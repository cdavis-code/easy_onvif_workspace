#!/usr/bin/env bash
# Build the `easy-onvif-web` npm artifact with dart2wasm.
#
# Outputs:
#   build/web/easy_onvif.wasm
#   build/web/easy_onvif.mjs
#   build/web/easy_onvif.support.js
#
# And stages a copy into `npm/easy-onvif-web/dist/`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WS_ROOT="$(cd "$PKG_DIR/../.." && pwd)"

BUILD_DIR="$PKG_DIR/build/web"
NPM_DIST="$WS_ROOT/npm/easy-onvif-web/dist"

mkdir -p "$BUILD_DIR" "$NPM_DIST"

echo "==> dart compile wasm -O2 -> $BUILD_DIR/easy_onvif.wasm"
cd "$PKG_DIR"
dart compile wasm \
  -O2 \
  -o "$BUILD_DIR/easy_onvif.wasm" \
  lib/entry/web.dart

echo "==> staging to $NPM_DIST/"
cp "$BUILD_DIR/easy_onvif.wasm" "$NPM_DIST/easy_onvif.wasm"
cp "$BUILD_DIR/easy_onvif.mjs" "$NPM_DIST/easy_onvif.mjs"

if [[ -f "$BUILD_DIR/easy_onvif.support.js" ]]; then
  cp "$BUILD_DIR/easy_onvif.support.js" "$NPM_DIST/easy_onvif.support.js"
fi

echo "==> done."
