#!/usr/bin/env bash
# Release the `easy-onvif-mcp` npm package.
#
# Usage (from anywhere in the repo):
#   bash packages/easy_onvif_mcp_js/tool/publish_npm.sh patch
#   bash packages/easy_onvif_mcp_js/tool/publish_npm.sh 0.2.0
#
# Bumps the npm version, rebuilds the dart2js runtime, commits both, and
# creates the `easy_onvif_mcp_js-v*` tag that the CI workflow publishes on.
# Nothing reaches npm until you `git push --tags`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WS_ROOT="$(cd "$PKG_DIR/../.." && pwd)"
NPM_DIR="$WS_ROOT/npm/easy-onvif-mcp"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <major|minor|patch|x.y.z>" >&2
  exit 1
fi

cd "$NPM_DIR"
echo "==> npm version bump ($1)"
NEW_VERSION="$(npm version --no-git-tag-version "$1")"
NEW_VERSION="${NEW_VERSION#v}"
echo "    new version: $NEW_VERSION"

# Keep the Dart entry's reported server version in step with the npm artifact.
ENTRY="$PKG_DIR/lib/easy_onvif_mcp_js.dart"
if grep -q "const String serverVersion = " "$ENTRY"; then
  sed -i.bak "s/const String serverVersion = '[^']*';/const String serverVersion = '$NEW_VERSION';/" "$ENTRY"
  rm -f "$ENTRY.bak"
  echo "    synced serverVersion in $(basename "$ENTRY")"
fi

echo "==> building dart2js runtime"
bash "$SCRIPT_DIR/build_mcp_node.sh"

# dist/ is gitignored (it is generated), so stage it explicitly, the same way
# the library artifacts under npm/easy-onvif-*/dist are tracked.
cd "$WS_ROOT"
git add "$NPM_DIR/package.json"
git add -f "$NPM_DIR/dist/easy_onvif_mcp.runtime.js"
git add "$ENTRY"

git commit -m "chore(easy_onvif_mcp_js): release v$NEW_VERSION"
git tag -a "easy_onvif_mcp_js-v$NEW_VERSION" \
  -m "Release easy-onvif-mcp v$NEW_VERSION"

echo ""
echo "==> ready. To publish:"
echo "    git push origin main --tags"
echo ""
echo "Or publish locally instead:"
echo "    cd npm/easy-onvif-mcp && npm publish --access=public"
