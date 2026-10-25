#!/usr/bin/env bash
# Publish the three npm artifacts to the registry, right now, from this checkout.
#
# This is the counterpart to `melos run release:npm[:mcp]`, which only bumps,
# builds, commits and tags and leaves the publish to CI. Use this when you want
# the packages live immediately (or when CI has no NPM_TOKEN yet).
#
#   melos run publish:npm              # build, then publish all three
#   melos run publish:npm -- --dry-run # build, then show what would ship
#
# Publishing a brand-new package name cannot be done from a CI automation
# token, so the first release of a name has to come from an interactive
# `npm login` session like this one.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN="${1:-}"

cd "$WS_ROOT"

if ! USER=$(npm whoami 2>/dev/null); then
  echo "not logged in to npmjs.org - run 'npm login' first" >&2
  exit 1
fi
echo "==> publishing as '$USER'"

# Rebuild first: npm/*/dist is what ships, and a stale tracked artifact would
# otherwise be published verbatim.
echo "==> rebuilding npm artifacts"
melos run build:npm
melos run build:npm:mcp

for PKG in easy-onvif-node easy-onvif-web easy-onvif-mcp; do
  echo "==> $PKG"
  if [ "$DRY_RUN" = "--dry-run" ]; then
    (cd "npm/$PKG" && npm publish --dry-run 2>&1 | tail -4)
  else
    (cd "npm/$PKG" && npm publish)
    VERSION=$(node -p "require('./npm/$PKG/package.json').version")
    echo "    published $PKG@$VERSION"
  fi
done

if [ "$DRY_RUN" != "--dry-run" ]; then
  # The rebuild may have changed tracked artifacts; say so instead of leaving
  # the repo inconsistent with what the registry now serves.
  if [ -n "$(git status --porcelain -- npm)" ]; then
    echo ""
    echo "note: the rebuild changed tracked files under npm/ - commit them so the"
    echo "      repository matches what is now on the registry:"
    git status --short -- npm
  fi
  echo ""
  echo "verify: https://www.npmjs.com/settings/$USER/packages"
fi
