import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_retriever/src/gallery_grid.dart';
import 'package:media_retriever/src/gallery_loader.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumsView extends StatefulWidget {
  const AlbumsView({
    required this.albums,
    required this.selectedIds,
    required this.onTap,
    required this.loader,
    super.key,
  });

  final List<AssetPathEntity> albums;

  /// Liste ordonnée des IDs sélectionnés (ordre = ordre de sélection
  /// utilisateur). Propagée jusqu'à [GalleryGrid] qui en déduit le numéro
  /// affiché sur chaque vignette.
  final List<String> selectedIds;
  final ValueChanged<AssetEntity> onTap;
  final GalleryLoader loader;

  @override
  State<AlbumsView> createState() => _AlbumsViewState();
}

class _AlbumsViewState extends State<AlbumsView> {
  /// Assets déjà chargés pour chaque album (null = pas encore chargé).
  final Map<String, List<AssetEntity>> _loadedAssets = {};

  /// Albums dont le chargement est en cours.
  final Set<String> _loading = {};

  /// Albums dont le chargement a échoué.
  final Map<String, String> _errors = {};

  Future<void> _loadAlbumAssets(AssetPathEntity album) async {
    if (_loadedAssets.containsKey(album.id) || _loading.contains(album.id)) {
      return;
    }
    setState(() {
      _loading.add(album.id);
      _errors.remove(album.id);
    });
    try {
      final assets = await widget.loader.loadAlbumAssets(album);
      if (mounted) {
        setState(() {
          _loadedAssets[album.id] = assets;
          _loading.remove(album.id);
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _errors[album.id] = e.toString();
          _loading.remove(album.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.albums.length,
      itemBuilder: (context, index) {
        final album = widget.albums[index];
        return _AlbumSection(
          album: album,
          assets: _loadedAssets[album.id],
          isLoading: _loading.contains(album.id),
          error: _errors[album.id],
          selectedIds: widget.selectedIds,
          onTap: widget.onTap,
          onExpand: () => unawaited(_loadAlbumAssets(album)),
        );
      },
    );
  }
}

class _AlbumSection extends StatefulWidget {
  const _AlbumSection({
    required this.album,
    required this.assets,
    required this.isLoading,
    required this.error,
    required this.selectedIds,
    required this.onTap,
    required this.onExpand,
  });

  final AssetPathEntity album;
  final List<AssetEntity>? assets;
  final bool isLoading;
  final String? error;
  final List<String> selectedIds;
  final ValueChanged<AssetEntity> onTap;
  final VoidCallback onExpand;

  @override
  State<_AlbumSection> createState() => _AlbumSectionState();
}

class _AlbumSectionState extends State<_AlbumSection> {
  int? _assetCount;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCount());
  }

  Future<void> _loadCount() async {
    final count = await widget.album.assetCountAsync;
    if (mounted) {
      setState(() => _assetCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final countLabel = _assetCount != null ? ' ($_assetCount)' : '';

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: EdgeInsets.zero,
      title: Text(
        '${widget.album.name}$countLabel',
        style: TextStyle(
          // fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      onExpansionChanged: (expanded) {
        if (expanded) widget.onExpand();
      },
      children: [_buildContent()],
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.error!,
          textAlign: TextAlign.center,
        ),
      );
    }

    final assets = widget.assets;
    if (assets == null) {
      // Pas encore chargé (n'a pas encore été déplié).
      return const SizedBox.shrink();
    }

    if (assets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Aucun média dans cet album')),
      );
    }

    return GalleryGrid(
      assets: assets,
      selectedIds: widget.selectedIds,
      onTap: widget.onTap,
      shrinkWrap: true,
    );
  }
}
