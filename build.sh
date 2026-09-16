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
# scripts/make-signing-cert.sh creates a stable "GridTile Dev" identity; it is used when present.
if [ -z "${CODESIGN_IDENTITY:-}" ] && security find-identity -v -p codesigning | grep -q '"GridTile Dev"'; then
  CODESIGN_IDENTITY="GridTile Dev"
fi
codesign --force --sign "${CODESIGN_IDENTITY:--}" "$APP"

pkill -x GridTile 2>/dev/null || true
rm -rf /Applications/GridTile.app
cp -R "$APP" /Applications/
echo "Installed /Applications/GridTile.app"
if [ -z "${CODESIGN_IDENTITY:-}" ]; then
  echo "Ad-hoc signed: macOS will drop the Accessibility grant on every rebuild."
  echo "Run ./scripts/make-signing-cert.sh once to fix that."
else
  echo "Signed with '$CODESIGN_IDENTITY'."
fi
