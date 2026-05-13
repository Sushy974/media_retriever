import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_retriever/src/albums_view.dart';
import 'package:media_retriever/src/camera_capture_page.dart';
import 'package:media_retriever/src/gallery_grid.dart';
import 'package:media_retriever/src/gallery_loader.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

enum _GalleryViewMode { flat, byAlbum }

class MediaPickerSheet extends StatefulWidget {
  const MediaPickerSheet({
    super.key,
    this.limit,
    this.kind = MediaKind.any,
    this.fileExtensions,
  });

  final int? limit;
  final MediaKind kind;

  /// Extensions autorisées pour le file picker (bouton dossier).
  /// Si null, les extensions par défaut sont déduites de [kind].
  final List<String>? fileExtensions;

  @override
  State<MediaPickerSheet> createState() => _MediaPickerSheetState();
}

class _MediaPickerSheetState extends State<MediaPickerSheet> {
  final GalleryLoader _galleryLoader = GalleryLoaderImpl();

  // --- Vue plate ---
  List<AssetEntity> _assets = [];
  bool _loading = true;
  String? _error;

  // --- Vue par album ---
  _GalleryViewMode _viewMode = _GalleryViewMode.flat;
  List<AssetPathEntity> _albums = [];
  bool _albumsLoading = false;
  String? _albumsError;

  // Sélection partagée entre les deux vues. On utilise une Map (qui en Dart
  // préserve l'ordre d'insertion) pour conserver l'ordre exact dans lequel
  // l'utilisateur a tapé sur les médias — ordre qu'on rendra visible via un
  // numéro de sélection (1, 2, 3…) sur les vignettes, et qu'on respectera au
  // moment du `pop` pour que les médias arrivent dans le bon ordre côté app.
  final Map<String, AssetEntity> _selectedAssets = <String, AssetEntity>{};

  @override
  void initState() {
    super.initState();
    unawaited(_loadAssets());
  }

  Future<void> _loadAlbums() async {
    if (_albumsLoading || _albums.isNotEmpty) return;
    setState(() {
      _albumsLoading = true;
      _albumsError = null;
    });
    try {
      final albums = await _galleryLoader.loadAlbums(widget.kind);
      if (mounted) {
        setState(() {
          _albums = albums;
          _albumsLoading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _albumsError = e.toString();
          _albumsLoading = false;
        });
      }
    }
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final assets = await _galleryLoader.loadGalleryAssets(widget.kind);
      if (mounted) {
        setState(() {
          _assets = assets;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _toggleSelection(AssetEntity entity) {
    setState(() {
      if (_selectedAssets.containsKey(entity.id)) {
        _selectedAssets.remove(entity.id);
      } else {
        final limit = widget.limit;
        if (limit != null && _selectedAssets.length >= limit) return;
        _selectedAssets[entity.id] = entity;
      }
    });
  }

  Future<void> _validateSelection() async {
    if (_selectedAssets.isEmpty) return;

    // On itère dans l'ordre d'insertion = ordre de sélection utilisateur.
    var selected = _selectedAssets.values.toList();
    final limit = widget.limit;
    if (limit != null && selected.length > limit) {
      selected = selected.take(limit).toList();
    }
    final xfiles = <XFile>[];
    for (final entity in selected) {
      // IMPORTANT:
      // Sur Android, `getFile()` peut générer un fichier "exporté" dans le
      // cache
      // (parfois visible/scané par certaines apps Galerie), ce qui ressemble à
      // un doublon. On préfère donc renvoyer le fichier d'origine de la galerie
      // quand il est disponible.
      final file = await entity.originFile ?? await entity.file;
      if (file != null) xfiles.add(XFile(file.path));
    }
    if (!mounted) return;
    Navigator.of(context).pop(xfiles);
  }

  Future<void> _openCamera() async {
    if (Platform.isIOS) {
      // Sur iOS, on laisse AVFoundation (plugin camera) gérer le prompt natif.
      debugPrint(
        '[media_retriever][permissions] openCamera(iOS) -> push camera',
      );

      final result = await Navigator.of(context).push<List<XFile>>(
        MaterialPageRoute(
          builder: (context) => CameraCapturePage(kind: widget.kind),
        ),
      );
      if (!mounted) return;
      if (result != null && result.isNotEmpty) {
        Navigator.of(context).pop(result);
      }
      return;
    }

    debugPrint(
      '[media_retriever][permissions] openCamera(status before) '
      'camera=${(await Permission.camera.status).name} '
      'microphone=${(await Permission.microphone.status).name}',
    );

    final camera = await Permission.camera.request();
    debugPrint(
      '[media_retriever][permissions] openCamera(request results) '
      'camera=${camera.name}',
    );
    if (!camera.isGranted) {
      final mustOpenSettings = camera.isPermanentlyDenied;
      if (mustOpenSettings && mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Autoriser la caméra'),
              content: Text(
                Platform.isIOS
                    ? 'Sur iPhone, active Caméra et Microphone pour Zibmarket '
                          'dans Réglages > Confidentialité et sécurité > Caméra '
                          'et Réglages > Confidentialité et sécurité > Micro.'
                    : 'Active Caméra et Microphone pour Zibmarket dans les '
                          'réglages.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await openAppSettings();
                  },
                  child: const Text('Ouvrir les réglages'),
                ),
              ],
            );
          },
        );
      }
      return;
    }
    if (!mounted) return;

    final result = await Navigator.of(context).push<List<XFile>>(
      MaterialPageRoute(
        builder: (context) => CameraCapturePage(kind: widget.kind),
      ),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _openFilePicker() async {
    final allowedExtensions = widget.fileExtensions ??
        switch (widget.kind) {
          MediaKind.photo => [
            'jpg',
            'jpeg',
            'png',
            'gif',
            'bmp',
            'webp',
            'heic',
            'heif',
          ],
          MediaKind.video => ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'],
          MediaKind.any => [
            'jpg',
            'jpeg',
            'png',
            'gif',
            'bmp',
            'webp',
            'heic',
            'heif',
            'mp4',
            'mov',
            'avi',
            'mkv',
            'webm',
            'm4v',
          ],
        };

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: widget.limit != 1,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    var files = result.files.where((f) => f.path != null).toList();
    final limit = widget.limit;
    if (limit != null && files.length > limit) {
      files = files.take(limit).toList();
    }

    final xfiles = files.map((f) => XFile(f.path!)).toList();
    if (xfiles.isNotEmpty && mounted) {
      Navigator.of(context).pop(xfiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topBar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              height: 5,
              width: 160,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SegmentedButton<_GalleryViewMode>(
                  style: SegmentedButton.styleFrom(
                    iconColor: Theme.of(
                      context,
                    ).colorScheme.secondary,
                    selectedBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary,
                    selectedForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimary,
                  ),
                  segments: [
                    ButtonSegment(
                      value: _GalleryViewMode.flat,
                      icon: const Icon(Icons.grid_view),
                      label: Text(
                        'Tous',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary,
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: _GalleryViewMode.byAlbum,
                      icon: const Icon(Icons.photo_library),
                      label: Text(
                        'Albums',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (selection) {
                    final mode = selection.first;
                    setState(() => _viewMode = mode);
                    if (mode == _GalleryViewMode.byAlbum) {
                      unawaited(_loadAlbums());
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    Widget body;
    if (_viewMode == _GalleryViewMode.byAlbum) {
      if (_albumsLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else if (_albumsError != null) {
        body = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_albumsError!, textAlign: TextAlign.center),
          ),
        );
      } else {
        body = AlbumsView(
          albums: _albums,
          selectedIds: _selectedAssets.keys.toList(),
          onTap: _toggleSelection,
          loader: _galleryLoader,
        );
      }
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    } else {
      body = GalleryGrid(
        assets: _assets,
        selectedIds: _selectedAssets.keys.toList(),
        onTap: _toggleSelection,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        topBar,
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: body,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton.filled(
                      onPressed: _openCamera,
                      icon: const Icon(Icons.camera_alt),
                      tooltip: 'Ouvrir la caméra',
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: _openFilePicker,
                      icon: const Icon(Icons.folder_open),
                      tooltip: 'Parcourir les fichiers',
                    ),
                  ],
                ),
                FilledButton(
                  onPressed:
                      _selectedAssets.isEmpty ? null : _validateSelection,
                  child: const Text('Valider'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
