import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:media_retriever/src/media_retriever_impl.dart';

void _validateLimit(int? limit) {
  if (limit != null && limit <= 0) {
    throw ArgumentError.value(
      limit,
      'limit',
      'limit must be null or greater than 0',
    );
  }
}

/// Flutter package for retrieving and handling media (images, video) from
/// multiple sources.
///
/// Create a [MediaRetriever] instance to open the gallery/camera picker
/// and get [File]s from the user selection.
class MediaRetriever {
  /// Creates a [MediaRetriever] instance.
  const MediaRetriever();

  /// Ouvre un bottom sheet permettant de sélectionner des médias dans la
  /// galerie ou d'en capturer un via la caméra.
  ///
  /// [limit] restreint le nombre de fichiers sélectionnables (null = illimité).
  /// Retourne une liste de [File], ou une liste vide si l'utilisateur annule
  /// ou si les permissions sont refusées.
  Future<List<File>> recupereMedias(
    BuildContext context, {
    int? limit,
  }) {
    _validateLimit(limit);
    return MediaRetrieverImpl.recupereMedias(
      context,
      limit: limit,
      kind: MediaKind.any,
    );
  }

  /// Ouvre un bottom sheet pour sélectionner ou capturer des photos uniquement.
  ///
  /// [limit] restreint le nombre de fichiers (null = illimité).
  Future<List<File>> recuperePhotos(
    BuildContext context, {
    int? limit,
  }) {
    _validateLimit(limit);
    return MediaRetrieverImpl.recupereMedias(
      context,
      limit: limit,
      kind: MediaKind.photo,
    );
  }

  /// Ouvre un bottom sheet pour sélectionner ou capturer des vidéos uniquement.
  ///
  /// [limit] restreint le nombre de fichiers (null = illimité).
  Future<List<File>> recupereVideos(
    BuildContext context, {
    int? limit,
  }) {
    _validateLimit(limit);
    return MediaRetrieverImpl.recupereMedias(
      context,
      limit: limit,
      kind: MediaKind.video,
    );
  }
}
