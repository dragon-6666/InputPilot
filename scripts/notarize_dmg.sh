#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DMG_PATH="${1:-$ROOT_DIR/dist/InputPilot.dmg}"

: "${NOTARY_KEY_ID:?Missing NOTARY_KEY_ID}"
: "${NOTARY_ISSUER_ID:?Missing NOTARY_ISSUER_ID}"
: "${NOTARY_KEY_PATH:?Missing NOTARY_KEY_PATH}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG not found: $DMG_PATH" >&2
  exit 1
fi

xcrun notarytool submit "$DMG_PATH" \
  --key "$NOTARY_KEY_PATH" \
  --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER_ID" \
  --wait

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl -a -vvv -t open "$DMG_PATH"
