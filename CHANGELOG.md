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
