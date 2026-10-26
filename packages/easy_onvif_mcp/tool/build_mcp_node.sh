#!/usr/bin/env bash
# Build the `easy-onvif-mcp` npm artifact with dart2js.
#
# Outputs:
#   build/mcp/easy_onvif_mcp.raw.js        (raw dart2js output)
#   build/mcp/easy_onvif_mcp.runtime.js    (preamble + raw output)
#
# and stages the runtime into `dist/` of this package, which is also the npm
# package directory.
#
# `bin/easy-onvif-mcp.js` is hand-maintained — it polyfills the browser globals
# the compiled bundle expects, then imports this runtime. Do NOT overwrite it
# from here.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WS_ROOT="$(cd "$PKG_DIR/../.." && pwd)"

BUILD_DIR="$PKG_DIR/build/mcp"
NPM_DIST="$PKG_DIR/dist"
PREAMBLE="$WS_ROOT/packages/easy_onvif_js/tool/node_preamble.js"

mkdir -p "$BUILD_DIR" "$NPM_DIST"

# -O4 is the strongest dart2js optimization; bundle size is the price of
# shipping the whole ONVIF SOAP stack plus dart_mcp in one file.
echo "==> dart compile js -O4 -> $BUILD_DIR/easy_onvif_mcp.raw.js"
cd "$PKG_DIR"
dart compile js \
  -O4 \
  -o "$BUILD_DIR/easy_onvif_mcp.raw.js" \
  lib/src/js/entry.dart

# Reuse the library's Node preamble: it installs `self`, `require`, `process`
# and `location`, which the compiled code (and node:dgram) needs under Node.
echo "==> prepending Node preamble -> $BUILD_DIR/easy_onvif_mcp.runtime.js"
cat "$PREAMBLE" "$BUILD_DIR/easy_onvif_mcp.raw.js" \
  > "$BUILD_DIR/easy_onvif_mcp.runtime.js"

echo "==> staging to $NPM_DIST/"
cp "$BUILD_DIR/easy_onvif_mcp.runtime.js" "$NPM_DIST/easy_onvif_mcp.runtime.js"

echo "==> done: $(wc -c < "$NPM_DIST/easy_onvif_mcp.runtime.js") bytes"
