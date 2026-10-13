#!/usr/bin/env bash
# Build the signed release APK and publish it as a GitHub Release.
# Phones running CV Ready see it under Akun > Pembaruan (and at launch).
#
#   1. Bump `version:` in pubspec.yaml (e.g. 1.0.1+2)
#   2. bash tool/release.sh "Catatan rilis singkat"
set -euo pipefail
cd "$(dirname "$0")/.."

VER=$(grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//')
NOTES="${1:-Pembaruan CV Ready $VER.}"
REPO="hilal1709/cv-ready"

[ -f .env.json ] || { echo ".env.json tidak ada"; exit 1; }
grep -q '"API_URL"' .env.json || { echo ".env.json harus berisi API_URL (alamat backend)"; exit 1; }
if grep -Eq '"(DB_PASSWORD|DB_USER|DB_HOST|ANTHROPIC_API_KEY|GEMINI_API_KEY)"' .env.json; then
  echo ".env.json masih berisi kredensial database/AI. Sisakan hanya API_URL sebelum merilis APK."; exit 1
fi
[ -f android/key.properties ] || { echo "android/key.properties tidak ada (keystore rilis)"; exit 1; }
gh release view "v$VER" -R "$REPO" >/dev/null 2>&1 && { echo "v$VER sudah dirilis. Naikkan version di pubspec.yaml."; exit 1; }

flutter build apk --release --dart-define-from-file=.env.json
APK="build/cv-ready-$VER.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$APK"

gh release create "v$VER" "$APK" -R "$REPO" --title "CV Ready $VER" --notes "$NOTES"
echo "Dirilis: https://github.com/$REPO/releases/tag/v$VER"
