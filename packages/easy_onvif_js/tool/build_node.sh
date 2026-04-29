#!/usr/bin/env bash
# Build the `easy-onvif-node` npm artifact with dart2js.
#
# Outputs:
#   build/node/easy_onvif.raw.js   (raw dart2js output)
#   build/node/easy_onvif.js       (preamble + raw output, staged to npm)
#
# And stages a copy into `npm/easy-onvif-node/dist/`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WS_ROOT="$(cd "$PKG_DIR/../.." && pwd)"

BUILD_DIR="$PKG_DIR/build/node"
NPM_DIST="$WS_ROOT/npm/easy-onvif-node/dist"

mkdir -p "$BUILD_DIR" "$NPM_DIST"

echo "==> dart compile js -O2 -> $BUILD_DIR/easy_onvif.raw.js"
cd "$PKG_DIR"
dart compile js \
  -O2 \
  -o "$BUILD_DIR/easy_onvif.raw.js" \
  lib/entry/node.dart

echo "==> prepending Node preamble -> $BUILD_DIR/easy_onvif.js"
cat "$SCRIPT_DIR/node_preamble.js" "$BUILD_DIR/easy_onvif.raw.js" \
  > "$BUILD_DIR/easy_onvif.js"

echo "==> staging to $NPM_DIST/"
cp "$BUILD_DIR/easy_onvif.js" "$NPM_DIST/easy_onvif.js"

# Clean up legacy WASM artifacts from previous builds so the npm package
# doesn't carry stale files.
rm -f \
  "$NPM_DIST/easy_onvif.wasm" \
  "$NPM_DIST/easy_onvif.mjs" \
  "$NPM_DIST/easy_onvif.support.js"

echo "==> done."
