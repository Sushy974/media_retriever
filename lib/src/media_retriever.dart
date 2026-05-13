import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
class MediaRetriever {
  const MediaRetriever();

  /// Ouvre un bottom sheet (mobile) ou un dialog (web) permettant de
  /// sélectionner des médias dans la galerie ou d'en capturer un via la caméra.
  ///
  /// [limit] restreint le nombre de fichiers sélectionnables (null = illimité).
  /// Retourne une liste de [XFile], ou une liste vide si l'utilisateur annule
  /// ou si les permissions sont refusées.
  Future<List<XFile>> recupereMedias(
    BuildContext context, {
    int? limit,
  }) {
    _validateLimit(limit);
    return recupereMediasPlatform(
      context,
      limit: limit,
      kind: MediaKind.any,
    );
  }

  /// Ouvre un bottom sheet (mobile) ou un dialog (web) pour sélectionner ou
  /// capturer des photos uniquement.
  ///
  /// [limit] restreint le nombre de fichiers (null = illimité).
  Future<List<XFile>> recuperePhotos(
    BuildContext context, {
    int? limit,
  }) {
    _validateLimit(limit);
    return recupereMediasPlatform(
      context,
      limit: limit,
      kind: MediaKind.photo,
    );
  }

  /// Ouvre un bottom sheet (mobile) ou un dialog (web) pour sélectionner ou
  /// capturer des vidéos uniquement.
  ///
  /// [limit] restreint le nombre de fichiers (null = illimité).
  Future<List<XFile>> recupereVideos(
    BuildContext context, {
    int? limit,
  }) {
    _validateLimit(limit);
    return recupereMediasPlatform(
      context,
      limit: limit,
      kind: MediaKind.video,
    );
  }

  /// Ouvre un bottom sheet (mobile) ou un dialog (web) pour récupérer
  /// un document : photo depuis la galerie, prise de photo via la caméra,
  /// ou fichier (PDF, images) depuis le système de fichiers.
  ///
  /// La galerie et la caméra restent en mode photo uniquement.
  /// Le bouton fichiers accepte les formats PDF et images courants.
  ///
  /// [limit] restreint le nombre de fichiers (null = illimité).
  Future<List<XFile>> recupereDocuments(
    BuildContext context, {
    int? limit,
  }) {
    _validateLimit(limit);
    return recupereMediasPlatform(
      context,
      limit: limit,
      kind: MediaKind.photo,
      fileExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
      ],
    );
  }
}
