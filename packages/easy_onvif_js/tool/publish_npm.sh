#!/usr/bin/env bash
# Release the `easy-onvif-node` and `easy-onvif-web` npm packages together.
#
# Usage (from anywhere in the repo):
#   bash packages/easy_onvif_js/tool/publish_npm.sh patch
#   bash packages/easy_onvif_js/tool/publish_npm.sh 3.1.5
#
# Both artifacts are built from this one Dart package, so they always share a
# version and a single `easy_onvif_js-v*` tag publishes both. The tag is what
# the CI workflow publishes on — nothing reaches npm until you push tags.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WS_ROOT="$(cd "$PKG_DIR/../.." && pwd)"
NODE_DIR="$WS_ROOT/npm/easy-onvif-node"
WEB_DIR="$WS_ROOT/npm/easy-onvif-web"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <major|minor|patch|x.y.z>" >&2
  echo "  Both npm packages are set to the same resolved version." >&2
  exit 1
fi

echo "==> resolving new version"
NEW_VERSION="$(cd "$NODE_DIR" && npm version --no-git-tag-version "$1")"
NEW_VERSION="${NEW_VERSION#v}"
echo "    new version: $NEW_VERSION"

(cd "$WEB_DIR" && npm version --no-git-tag-version --allow-same-version "$NEW_VERSION")

echo "==> building node (dart2js) and web (dart2wasm) artifacts"
bash "$SCRIPT_DIR/build_node.sh"
bash "$SCRIPT_DIR/build_web.sh"

# Smoke-test the node bundle before committing a release that references it.
node "$SCRIPT_DIR/smoke_test_node.mjs"

# dist/ is generated (gitignored), so stage it explicitly the way these
# artifacts have always been checked in.
cd "$WS_ROOT"
git add "$NODE_DIR/package.json" "$WEB_DIR/package.json"
git add -f "$NODE_DIR/dist/easy_onvif.js"
git add -f "$WEB_DIR/dist/easy_onvif.wasm" "$WEB_DIR/dist/easy_onvif.mjs" "$WEB_DIR/dist/easy_onvif.support.js"

git commit -m "chore(easy_onvif_js): release npm v$NEW_VERSION"
git tag -a "easy_onvif_js-v$NEW_VERSION" \
  -m "Release easy-onvif-node and easy-onvif-web v$NEW_VERSION"

echo ""
echo "==> ready. To publish:"
echo "    git push origin main --tags"
echo ""
echo "Or publish locally instead:"
echo "    cd npm/easy-onvif-node && npm publish --access=public"
echo "    cd npm/easy-onvif-web  && npm publish --access=public"
