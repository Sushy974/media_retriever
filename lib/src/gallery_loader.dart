import 'package:flutter/foundation.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:photo_manager/photo_manager.dart';

abstract interface class GalleryLoader {
  Future<List<AssetEntity>> loadGalleryAssets(MediaKind kind);
}

class GalleryLoaderImpl implements GalleryLoader {
  static const int _pageSize = 500;

  @override
  Future<List<AssetEntity>> loadGalleryAssets(MediaKind kind) async {
    // #region agent log
    debugPrint('[media_retriever][gallery] loadGalleryAssets(entry) kind=$kind');
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
