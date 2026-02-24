import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

abstract interface class MediaPermissions {
  /// Demande l'accès à la galerie (photos + vidéos).
  ///
  /// Si refusé, le picker ne s'ouvre pas.
  Future<bool> requestGallery();

  /// Demande uniquement les permissions nécessaires pour [kind].
  Future<bool> requestForKind(MediaKind kind);
}

class MediaPermissionsImpl implements MediaPermissions {
  @override
  Future<bool> requestGallery() async {
    // #region agent log
    debugPrint(
      '[media_retriever][permissions] requestGallery(entry)',
    );
    // #endregion

    if (Platform.isIOS) {
      final state = await PhotoManager.requestPermissionExtend();
      // #region agent log
      debugPrint(
        '[media_retriever][permissions] iOS PhotoManager state=${state.name}',
      );
      // #endregion

      final result = state.hasAccess;
      // #region agent log
      debugPrint(
        '[media_retriever][permissions] requestGallery(exit) result=$result',
      );
      // #endregion
      return result;
    }

    // Android (notamment 13+): permissions séparées images/vidéos.
    // #region agent log
    debugPrint(
      '[media_retriever][permissions] status(before) '
      'photos=${(await Permission.photos.status).name} '
      'videos=${(await Permission.videos.status).name}',
    );
    // #endregion

    final photos = await Permission.photos.request();
    final videos = await Permission.videos.request();
    // #region agent log
    debugPrint(
      '[media_retriever][permissions] request results '
      'photos=${photos.name} videos=${videos.name}',
    );
    // #endregion

    final photosOk = photos.isGranted || photos.isLimited;
    final videosOk = !Platform.isAndroid || videos.isGranted;
    final result = photosOk && videosOk;

    // #region agent log
    debugPrint(
      '[media_retriever][permissions] requestGallery(exit) '
      'result=$result',
    );
    // #endregion
    return result;
  }

  @override
  Future<bool> requestForKind(MediaKind kind) async {
    if (Platform.isIOS) {
      final state = await PhotoManager.requestPermissionExtend();
      return state.hasAccess;
    }

    switch (kind) {
      case MediaKind.any:
        return requestGallery();
      case MediaKind.photo:
        final photos = await Permission.photos.request();
        return photos.isGranted || photos.isLimited;
      case MediaKind.video:
        final videos = await Permission.videos.request();
        return videos.isGranted;
    }
  }
}
