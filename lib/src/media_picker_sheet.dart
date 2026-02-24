import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_retriever/src/camera_capture_page.dart';
import 'package:media_retriever/src/gallery_grid.dart';
import 'package:media_retriever/src/gallery_loader.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaPickerSheet extends StatefulWidget {
  const MediaPickerSheet({
    super.key,
    this.limit,
    this.kind = MediaKind.any,
  });

  final int? limit;
  final MediaKind kind;

  @override
  State<MediaPickerSheet> createState() => _MediaPickerSheetState();
}

class _MediaPickerSheetState extends State<MediaPickerSheet> {
  final GalleryLoader _galleryLoader = GalleryLoaderImpl();
  List<AssetEntity> _assets = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAssets());
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
      if (_selectedIds.contains(entity.id)) {
        _selectedIds.remove(entity.id);
      } else {
        final limit = widget.limit;
        if (limit != null && _selectedIds.length >= limit) return;
        _selectedIds.add(entity.id);
      }
    });
  }

  Future<void> _validateSelection() async {
    if (_selectedIds.isEmpty) return;

    var selected = _assets.where((a) => _selectedIds.contains(a.id)).toList();
    final limit = widget.limit;
    if (limit != null && selected.length > limit) {
      selected = selected.take(limit).toList();
    }
    final files = <File>[];
    for (final entity in selected) {
      // IMPORTANT:
      // Sur Android, `getFile()` peut générer un fichier "exporté" dans le
      // cache
      // (parfois visible/scané par certaines apps Galerie), ce qui ressemble à
      // un doublon. On préfère donc renvoyer le fichier d'origine de la galerie
      // quand il est disponible.
      final file =
          await entity.originFile ??
          await entity.getFile(isOrigin: true) ??
          await entity.getFile();
      if (file != null) files.add(file);
    }
    if (!mounted) return;
    Navigator.of(context).pop(files);
  }

  Future<void> _openCamera() async {
    if (Platform.isIOS) {
      // Sur iOS, on laisse AVFoundation (plugin camera) gérer le prompt natif.
      debugPrint(
        '[media_retriever][permissions] openCamera(iOS) -> push camera',
      );

      final result = await Navigator.of(context).push<List<File>>(
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

    final result = await Navigator.of(context).push<List<File>>(
      MaterialPageRoute(
        builder: (context) => CameraCapturePage(kind: widget.kind),
      ),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topBar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Stack(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(top: 10),
              height: 5,
              width: 160,
            ),
          ),
          Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
        
            
            Flexible(
              child: FilledButton(
                onPressed: _selectedIds.isEmpty ? null : _validateSelection,
                child: const Text('Valider'),
              ),
            ),
          ],
        ),
        ],
      ),
    );

    Widget body;
    if (_loading) {
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
        selectedIds: _selectedIds,
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton.filled(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt),
                tooltip: 'Ouvrir la caméra',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
