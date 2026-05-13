## 0.2.1

- **Documentation**: ajout de captures d'écran dans le README pour illustrer le package sur pub.dev.

## 0.2.0

- **Web support**: ajout d'un picker dédié au web (`web_media_picker_dialog`) avec drag & drop via `desktop_drop` et `file_picker`.
- **Architecture**: séparation `media_retriever_mobile.dart` / `media_retriever_web.dart` / `media_retriever_stub.dart` via conditional imports.
- **Albums**: ajout de `albums_view` pour la navigation par album dans la galerie.
- **Nouvelle API**: `recupereDocuments` pour récupérer photos + fichiers (PDF, images) depuis galerie, caméra ou système de fichiers.
- **Dépendances**: ajout de `file_picker`, `desktop_drop`, `path`.

## 0.1.1+1

- **Documentation**: dartdoc ajouté pour le constructeur `MediaRetriever()`.
- **Example**: ajout d’une application d’exemple dans `example/` (requis pour les pub points).
- **Compatibilité**: utilisation de `originFile` et `file` au lieu de `getFile()` pour la compatibilité avec les contraintes minimales de `photo_manager` (downgrade / pub points).
- **Style**: dépendances triées par ordre alphabétique dans `pubspec.yaml`.

## 0.1.0+1

- Initial release.
- Retrieve media (images, video) from gallery and camera.
- Support for `recupereMedias`, `recuperePhotos`, `recupereVideos` with optional `limit`.
- iOS and Android support.
