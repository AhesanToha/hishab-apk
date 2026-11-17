#!/usr/bin/env bash
# Restore binary files (PNG icons + Gradle wrapper jar) that are stored
# base64-encoded in this folder, because the Muse GitHub connector can
# only push UTF-8 text files. Run from the repo root before `flutter build`.
set -euo pipefail
mkdir -p assets android/app/src/main/res/mipmap-hdpi android/app/src/main/res/mipmap-mdpi android/app/src/main/res/mipmap-xhdpi android/app/src/main/res/mipmap-xxhdpi android/app/src/main/res/mipmap-xxxhdpi android/app/src/main/res/mipmap-anydpi-v26 android/gradle/wrapper
base64 -d github-binaries/assets-logo.png.b64 > assets/logo.png
base64 -d github-binaries/assets-logo.png.b64 > android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_foreground.png
base64 -d github-binaries/mipmap-hdpi-ic_launcher.png.b64 > android/app/src/main/res/mipmap-hdpi/ic_launcher.png
base64 -d github-binaries/mipmap-mdpi-ic_launcher.png.b64 > android/app/src/main/res/mipmap-mdpi/ic_launcher.png
base64 -d github-binaries/mipmap-xhdpi-ic_launcher.png.b64 > android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
base64 -d github-binaries/mipmap-xxhdpi-ic_launcher.png.b64 > android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
base64 -d github-binaries/mipmap-xxxhdpi-ic_launcher.png.b64 > android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
base64 -d github-binaries/gradle-wrapper.jar.b64 > android/gradle/wrapper/gradle-wrapper.jar
echo "Binaries restored."
