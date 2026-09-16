#!/bin/bash
# Builds GridTile.app and installs it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=build/GridTile.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/GridTile "$APP/Contents/MacOS/GridTile"
cp Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp assets/GridTile.icns "$APP/Contents/Resources/GridTile.icns"
codesign --force --sign - "$APP"

pkill -x GridTile 2>/dev/null || true
rm -rf /Applications/GridTile.app
cp -R "$APP" /Applications/
echo "Installed /Applications/GridTile.app"
echo "Ad-hoc signature changes every build: re-grant Accessibility and re-toggle Launch at Login after each install."
