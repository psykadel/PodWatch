#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$ROOT_DIR/PodWatch.xcodeproj"
SCHEME_NAME="PodWatch"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="$ROOT_DIR/build/DerivedData"
ARTIFACTS_DIR="$ROOT_DIR/build/Artifacts"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/PodWatch.app"
DMG_STAGING_DIR="$ARTIFACTS_DIR/dmg-root"
DMG_PATH="$ARTIFACTS_DIR/PodWatch.dmg"

mkdir -p "$ARTIFACTS_DIR"
rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"
cp -R "$APP_PATH" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "PodWatch" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo
echo "Build succeeded:"
echo "$APP_PATH"
echo
echo "DMG created:"
echo "$DMG_PATH"
