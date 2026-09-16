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
# Ad-hoc signing changes the code hash every build, which invalidates the Accessibility grant.
# Set CODESIGN_IDENTITY to a self-signed "Code Signing" certificate from Keychain Access to keep it.
codesign --force --sign "${CODESIGN_IDENTITY:--}" "$APP"

pkill -x GridTile 2>/dev/null || true
rm -rf /Applications/GridTile.app
cp -R "$APP" /Applications/
echo "Installed /Applications/GridTile.app"
[ -z "${CODESIGN_IDENTITY:-}" ] && echo "Ad-hoc signed: remove and re-add GridTile in Accessibility, and re-toggle Launch at Login. Set CODESIGN_IDENTITY to avoid this." || true
