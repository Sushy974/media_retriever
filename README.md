# Media Retriever

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

Flutter package for retrieving and handling media (images, video) from multiple sources.  
Supported platforms: **iOS** and **Android**.

## Installation

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  media_retriever: ^0.1.0
```

### Permissions (application native) — obligatoires

Pour que le package fonctionne (galerie + caméra + enregistrement vidéo avec son), votre app **doit** déclarer les droits natifs suivants. Le package ne les ajoute pas ; c’est à vous de les configurer. Sans eux, le sélecteur ne s’ouvrira pas ou renverra une liste vide.

**iOS** — à ajouter dans `ios/Runner/Info.plist` :

| Clé                              | Rôle                                                      |
| -------------------------------- | --------------------------------------------------------- |
| `NSPhotoLibraryUsageDescription` | Accès à la photothèque pour sélectionner des médias.      |
| `NSCameraUsageDescription`       | Accès à la caméra pour capturer photos et vidéos.         |
| `NSMicrophoneUsageDescription`   | Accès au micro pour enregistrer l’audio lors d’une vidéo. |

Exemple minimal :

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Accès à la photothèque pour sélectionner des médias.</string>
<key>NSCameraUsageDescription</key>
<string>Accès à la caméra pour capturer des photos et vidéos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Accès au micro pour enregistrer l'audio lors d'une vidéo.</string>
```

Optionnel : si votre app **sauvegarde** aussi des photos/vidéos dans la photothèque, ajoutez :

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Accès pour sauvegarder des photos et vidéos dans la bibliothèque photo.</string>
```

**Android** — à ajouter dans `android/app/src/main/AndroidManifest.xml` (dans `<manifest>`, avant `<application>`) :

| Permission              | Rôle                                |
| ----------------------- | ----------------------------------- |
| `CAMERA`                | Capturer photos et vidéos.          |
| `RECORD_AUDIO`          | Enregistrer le son dans les vidéos. |
| `READ_EXTERNAL_STORAGE` | Lire la galerie (Android &lt; 13).  |
| `READ_MEDIA_IMAGES`     | Lire les images (Android 13+).      |
| `READ_MEDIA_VIDEO`      | Lire les vidéos (Android 13+).      |

Exemple :

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

Optionnel : sur anciennes versions d’Android, si votre app écrit des fichiers sur le stockage externe, vous pouvez ajouter `WRITE_EXTERNAL_STORAGE` (certaines apps l’utilisent pour la compatibilité).

Si l’utilisateur refuse les permissions, le picker ne s’ouvre pas et les méthodes du package renvoient une liste vide. Chaque appel peut déclencher une nouvelle demande de permission.

#### Exemple d’intégration (app Zibmarket)

L’app [Zibmarket](https://github.com/nathanchateau/zibmarket) utilise ce package. Voici ce qui a été mis en place côté natif pour que la galerie et la caméra fonctionnent.

**iOS** (`apps/zibmarket_app/ios/Runner/Info.plist`) — libellés utilisateur :

```xml
<key>NSCameraUsageDescription</key>
<string>Zibmarket utilise la caméra pour permettre aux professionnels de photographier et filmer leurs produits, ainsi que pour que les utilisateurs puissent prendre leur photo de profil ou envoyer des photos dans le chat.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Zibmarket utilise le microphone pour enregistrer le son lors de la création de vidéos de produits par les professionnels.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Zibmarket nécessite l'accès à votre bibliothèque photo pour sélectionner des images de produits, votre photo de profil ou des photos à envoyer dans le chat.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Zibmarket nécessite l'accès pour sauvegarder des photos et vidéos de produits dans votre bibliothèque photo.</string>
```

**Android** (`apps/zibmarket_app/android/app/src/main/AndroidManifest.xml`) — permissions liées au média (extrait) :

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

Vous pouvez vous inspirer de ces libellés et les adapter à votre contexte.

## Usage

### Récupérer des médias (photos et vidéos)

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_retriever/media_retriever.dart';

final retriever = MediaRetriever();

// Sans limite de sélection
final List<File> files = await retriever.recupereMedias(context);

// Limiter à 3 fichiers maximum
final List<File> limited = await retriever.recupereMedias(context, limit: 3);

if (files.isEmpty) {
  // User cancelled or permissions denied
} else {
  // Use files (from gallery selection or single camera capture)
}
```

### Récupérer uniquement des photos

```dart
final photos = await retriever.recuperePhotos(context, limit: 5);
```

La galerie n’affiche que les images ; le bouton caméra est en mode photo uniquement.

### Récupérer uniquement des vidéos

```dart
final videos = await retriever.recupereVideos(context, limit: 1);
```

La galerie n’affiche que les vidéos ; le bouton caméra est en mode vidéo uniquement.

### Paramètre `limit`

- `limit: null` (défaut) — sélection illimitée.
- `limit: n` avec `n > 0` — au plus `n` fichiers sélectionnables. Une exception est levée si `limit <= 0`.

- **Galerie** : l’utilisateur sélectionne un ou plusieurs médias puis appuie sur « Valider ». Le nombre de sélections est plafonné par `limit`.
- **Caméra** : bouton en bas à gauche ; selon la méthode, la caméra est en mode photo uniquement, vidéo uniquement, ou les deux. Retourne une liste d’un fichier.

---

## Continuous Integration 🤖

Media Retriever comes with a built-in [GitHub Actions workflow][github_actions_link] powered by [Very Good Workflows][very_good_workflows_link] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Workflows][very_good_coverage_link].

---

## Running Tests 🧪

For first time users, install the [very_good_cli][very_good_cli_link]:

```sh
dart pub global activate very_good_cli
```

To run all unit tests:

```sh
very_good test --coverage
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
