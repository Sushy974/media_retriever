# Intégration iOS et Android — checklist

Pour que **media_retriever** fonctionne (galerie + caméra + vidéo avec son), votre app doit déclarer les droits natifs suivants. Sans eux, le sélecteur ne s’ouvrira pas ou renverra une liste vide.

## iOS

**Fichier :** `ios/Runner/Info.plist`

| Clé | Obligatoire | Rôle |
|-----|-------------|------|
| `NSPhotoLibraryUsageDescription` | Oui | Accès à la photothèque pour sélectionner des médias. |
| `NSCameraUsageDescription` | Oui | Accès à la caméra pour capturer photos et vidéos. |
| `NSMicrophoneUsageDescription` | Oui | Accès au micro pour enregistrer l’audio lors d’une vidéo. |
| `NSPhotoLibraryAddUsageDescription` | Non | Uniquement si l’app sauvegarde des photos/vidéos dans la photothèque. |

## Android

**Fichier :** `android/app/src/main/AndroidManifest.xml` (dans `<manifest>`, avant `<application>`)

| Permission | Obligatoire | Rôle |
|------------|-------------|------|
| `android.permission.CAMERA` | Oui | Capturer photos et vidéos. |
| `android.permission.RECORD_AUDIO` | Oui | Enregistrer le son dans les vidéos. |
| `android.permission.READ_EXTERNAL_STORAGE` | Oui | Lire la galerie (Android &lt; 13). |
| `android.permission.READ_MEDIA_IMAGES` | Oui | Lire les images (Android 13+). |
| `android.permission.READ_MEDIA_VIDEO` | Oui | Lire les vidéos (Android 13+). |
| `android.permission.WRITE_EXTERNAL_STORAGE` | Non | Écriture sur stockage externe (compat anciennes versions, si l’app écrit des fichiers). |

## Résumé

- **iOS** : au minimum 3 clés dans `Info.plist` (photothèque, caméra, micro).
- **Android** : au minimum 5 permissions dans `AndroidManifest.xml` (caméra, audio, lecture galerie/images/vidéo).

Exemples complets et libellés utilisateur : voir le [README](README.md#permissions-application-native--obligatoires).
