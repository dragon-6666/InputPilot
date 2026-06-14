#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="InputPilot"
APP_DIR="$DIST_DIR/$APP_NAME.app"
BIN_PATH="$ROOT_DIR/.build/apple/arm64-apple-macosx/release/$APP_NAME"
SIGN_IDENTITY="${DEVELOPER_ID_APPLICATION:-}"

rm -rf "$DIST_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swift build \
  -c release \
  --arch arm64 \
  --build-path "$ROOT_DIR/.build/apple"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Packaging/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$ROOT_DIR/Packaging/MenuBarIconTemplate.png" "$APP_DIR/Contents/Resources/MenuBarIconTemplate.png"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "Signing app with Developer ID: $SIGN_IDENTITY"
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$SIGN_IDENTITY" \
    "$APP_DIR"
else
  echo "DEVELOPER_ID_APPLICATION not set, using ad-hoc signature for local testing."
  codesign --force --deep --sign - "$APP_DIR"
fi

codesign --verify --deep --strict --verbose=2 "$APP_DIR"
echo "$APP_DIR"
