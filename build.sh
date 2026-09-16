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
codesign --force --sign - "$APP"

pkill -x GridTile 2>/dev/null || true
rm -rf /Applications/GridTile.app
cp -R "$APP" /Applications/
echo "Installed /Applications/GridTile.app"
echo "Ad-hoc signature changes every build: re-grant Accessibility in System Settings > Privacy & Security > Accessibility after each install."
