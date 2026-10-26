#!/usr/bin/env bash
# Release the `easy-onvif-mcp` npm package.
#
# Usage (from anywhere in the repo):
#   bash packages/easy_onvif_mcp/tool/publish_npm.sh patch
#   bash packages/easy_onvif_mcp/tool/publish_npm.sh 0.2.0
#
# Bumps the npm version, rebuilds the dart2js runtime, commits both, and
# creates the `easy_onvif_mcp-v*` tag that the CI workflow publishes on.
# Nothing reaches npm until you `git push --tags`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WS_ROOT="$(cd "$PKG_DIR/../.." && pwd)"
META="$PKG_DIR/lib/meta.dart"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <major|minor|patch|x.y.z>" >&2
  exit 1
fi

cd "$PKG_DIR"
echo "==> npm version bump ($1)"
NEW_VERSION="$(npm version --no-git-tag-version "$1")"
NEW_VERSION="${NEW_VERSION#v}"
echo "    new version: $NEW_VERSION"

# Keep the Dart-reported server version in step with the npm artifact.
sed -i.bak "s/const String serverVersion = '[^']*';/const String serverVersion = '$NEW_VERSION';/" "$META"
rm -f "$META.bak"

echo "==> building dart2js runtime"
bash "$SCRIPT_DIR/build_mcp_node.sh"

# dist/ is gitignored (it is generated), so stage it explicitly, the same way
# the library artifacts under packages/easy_onvif_js/easy-onvif-*/dist are
# tracked.
cd "$WS_ROOT"
git add "$PKG_DIR/package.json" "$META"
git add -f "$PKG_DIR/dist/easy_onvif_mcp.runtime.js"

git commit -m "chore(easy_onvif_mcp): release v$NEW_VERSION"
git tag -a "easy_onvif_mcp-v$NEW_VERSION" \
  -m "Release easy-onvif-mcp v$NEW_VERSION"

echo ""
echo "==> ready. To publish:"
echo "    git push origin main --tags"
echo ""
echo "Or publish locally instead:"
echo "    cd packages/easy_onvif_mcp && npm publish --access=public"
