import 'package:flutter/foundation.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:photo_manager/photo_manager.dart';

abstract interface class GalleryLoader {
  Future<List<AssetEntity>> loadGalleryAssets(MediaKind kind);
  Future<List<AssetPathEntity>> loadAlbums(MediaKind kind);
  Future<List<AssetEntity>> loadAlbumAssets(AssetPathEntity album);
}

class GalleryLoaderImpl implements GalleryLoader {
  static const int _pageSize = 500;

  @override
  Future<List<AssetEntity>> loadGalleryAssets(MediaKind kind) async {
    // #region agent log
    debugPrint(
      '[media_retriever][gallery] loadGalleryAssets(entry) kind=$kind',
    );
    // #endregion

    final seenIds = <String>{};
    final all = <AssetEntity>[];

    if (kind == MediaKind.any || kind == MediaKind.photo) {
      final imagePaths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );
      for (final path in imagePaths) {
        final list = await _loadAllFromPath(path);
        for (final e in list) {
          if (seenIds.add(e.id)) all.add(e);
        }
      }
    }

    if (kind == MediaKind.any || kind == MediaKind.video) {
      final videoPaths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.video,
      );
      for (final path in videoPaths) {
        final list = await _loadAllFromPath(path);
        for (final e in list) {
          if (seenIds.add(e.id)) all.add(e);
        }
      }
    }

    all.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    // #region agent log
    debugPrint('[media_retriever][gallery] loaded total=${all.length}');
    // #endregion
    return all;
  }

  @override
  Future<List<AssetPathEntity>> loadAlbums(MediaKind kind) async {
    // #region agent log
    debugPrint('[media_retriever][gallery] loadAlbums(entry) kind=$kind');
    // #endregion

    final type = switch (kind) {
      MediaKind.photo => RequestType.image,
      MediaKind.video => RequestType.video,
      MediaKind.any => RequestType.common,
    };

    final albums = await PhotoManager.getAssetPathList(
      type: type,
    );

    albums.sort((a, b) {
      final aDate = a.lastModified;
      final bDate = b.lastModified;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    // #region agent log
    debugPrint('[media_retriever][gallery] loadAlbums total=${albums.length}');
    // #endregion
    return albums;
  }

  @override
  Future<List<AssetEntity>> loadAlbumAssets(AssetPathEntity album) async {
    // #region agent log
    debugPrint(
      '[media_retriever][gallery] loadAlbumAssets album=${album.name}',
    );
    // #endregion
    return _loadAllFromPath(album);
  }

  Future<List<AssetEntity>> _loadAllFromPath(AssetPathEntity path) async {
    final list = <AssetEntity>[];
    var page = 0;
    while (true) {
      final chunk = await path.getAssetListPaged(
        page: page,
        size: _pageSize,
      );
      if (chunk.isEmpty) break;
      list.addAll(chunk);
      if (chunk.length < _pageSize) break;
      page++;
    }
    return list;
  }
}
