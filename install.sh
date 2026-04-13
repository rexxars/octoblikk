#!/bin/bash
set -euo pipefail

APP_NAME="Octoblikk"
APP_DIR="$HOME/Applications/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "Building release binary..."
swift build -c release

RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Installing to $APP_DIR..."
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp .build/release/octoblikk "$MACOS_DIR/"
cp Sources/Resources/Info.plist "$CONTENTS_DIR/"
cp Sources/Resources/AppIcon.icns "$RESOURCES_DIR/"
cp -R .build/apple/Products/Release/octoblikk_octoblikk.bundle "$RESOURCES_DIR/" 2>/dev/null \
  || cp -R .build/arm64-apple-macosx/release/octoblikk_octoblikk.bundle "$RESOURCES_DIR/"

# Kill running instance if any, so the new one takes over
pkill -x octoblikk 2>/dev/null && echo "Stopped running instance." || true

echo "Done. Opening $APP_NAME..."
open "$APP_DIR"
