#!/bin/bash
set -euo pipefail

APP_NAME="Octoblikk"
APP_DIR="$HOME/Applications/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "Building release binary..."
swift build -c release

echo "Installing to $APP_DIR..."
mkdir -p "$MACOS_DIR"
cp .build/release/octoblikk "$MACOS_DIR/"
cp Sources/Resources/Info.plist "$CONTENTS_DIR/"

# Kill running instance if any, so the new one takes over
pkill -x octoblikk 2>/dev/null && echo "Stopped running instance." || true

echo "Done. Opening $APP_NAME..."
open "$APP_DIR"
