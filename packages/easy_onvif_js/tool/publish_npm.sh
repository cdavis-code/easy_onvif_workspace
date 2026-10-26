#!/usr/bin/env bash
# Release the `easy-onvif` npm package (Node.js + browser runtimes).
#
# Usage (from anywhere in the repo):
#   bash packages/easy_onvif_js/tool/publish_npm.sh patch
#   bash packages/easy_onvif_js/tool/publish_npm.sh 3.2.1
#
# Both runtimes are built from this one Dart package and ship as one npm
# package, so they share a version and a single `easy_onvif_js-v*` tag. The tag
# is what the CI workflow publishes on — nothing reaches npm until you push
# tags.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WS_ROOT="$(cd "$PKG_DIR/../.." && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <major|minor|patch|x.y.z>" >&2
  exit 1
fi

cd "$PKG_DIR"
echo "==> npm version bump ($1)"
NEW_VERSION="$(npm version --no-git-tag-version "$1")"
NEW_VERSION="${NEW_VERSION#v}"
echo "    new version: $NEW_VERSION"

echo "==> building the node (dart2js) and web (dart2wasm) runtimes"
bash "$SCRIPT_DIR/build_node.sh"
bash "$SCRIPT_DIR/build_web.sh"

# Exercise the shipped entry points before committing a release that references
# them: the node loader over real interop, the web loader's artifacts.
node "$SCRIPT_DIR/smoke_test_node.mjs"
node "$PKG_DIR/test/web/artifacts.mjs"

# dist/ is generated (gitignored), so stage it explicitly the way these
# artifacts have always been checked in.
cd "$WS_ROOT"
git add "$PKG_DIR/package.json"
git add -f "$PKG_DIR/dist/node/easy_onvif.js"
git add -f "$PKG_DIR/dist/web/easy_onvif.wasm" "$PKG_DIR/dist/web/easy_onvif.mjs" "$PKG_DIR/dist/web/easy_onvif.support.js"

git commit -m "chore(easy_onvif_js): release npm v$NEW_VERSION"
git tag -a "easy_onvif_js-v$NEW_VERSION" \
  -m "Release easy-onvif v$NEW_VERSION"

echo ""
echo "==> ready. To publish:"
echo "    git push origin main --tags"
echo ""
echo "Or publish locally instead (a brand-new npm name cannot be created by a"
echo "restricted CI token, so the first release must come from an npm login):"
echo "    cd packages/easy_onvif_js && npm publish --access=public"
