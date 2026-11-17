# Binary files, stored as base64

The Muse GitHub connector can only push UTF-8 text files, so the binary
files this Flutter project needs (the Logo 3 app icon PNGs and the Gradle
wrapper jar) are stored here as base64 text. GitHub Actions restores them
with `bash github-binaries/restore.sh` before `flutter build apk`.

Do not delete this folder: without it the Actions build has no app icon,
no `assets/logo.png`, and no Gradle wrapper.
