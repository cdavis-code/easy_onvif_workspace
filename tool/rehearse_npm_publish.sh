#!/usr/bin/env bash
# Rehearse the npm releases against an ephemeral registry.
#
# `npm publish` is irreversible in a way that costs (pub.dev versions are
# immutable, npm unpublish is penalized), and the real registry cannot be
# exercised from CI without a credential. This publishes the exact tarballs the
# release jobs would ship to a throwaway Verdaccio instance, installs them back
# as a consumer would, and runs them — so packaging defects surface on a pull
# request instead of in the registry.
#
# It has caught: a declared-but-missing LICENSE (silently never shipped), a
# stale tracked wasm artifact, and missing files in the `files` allowlist.
#
# Usage: bash tool/rehearse_npm_publish.sh [path-to-npm-dir]
#   default path is <repo>/npm, i.e. the working tree; CI passes the directory
#   it downloaded from the build-npm artifact so the rehearsal matches the
#   publish inputs byte for byte.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NPM_DIR="${1:-$WS_ROOT/npm}"

PACKAGES=(easy-onvif-node easy-onvif-web easy-onvif-mcp)
PORT=4873
# npm wants a trailing slash on --registry; the HTTP API paths must not be
# joined onto it (http://host:4873//-/ping 404s, which looks like a server that
# never started). Keep the slash-free base for curl.
BASE="http://127.0.0.1:$PORT"
REGISTRY="$BASE/"

# Belt and braces: never let a misconfigured run talk to the real registry.
case "$REGISTRY" in
  *127.0.0.1*|*localhost*) ;;
  *) echo "refusing to publish to non-local registry: $REGISTRY" >&2; exit 1 ;;
esac

WORK="$(mktemp -d)"
REG_PID=""

cleanup() {
  if [ -n "$REG_PID" ]; then kill "$REG_PID" 2>/dev/null || true; fi
  rm -rf "$WORK"
}
trap cleanup EXIT

mkdir -p "$WORK/storage"
cat > "$WORK/config.yaml" <<YAML
storage: $WORK/storage
auth:
  htpasswd:
    file: $WORK/htpasswd
    algorithm: bcrypt
    max_users: 1000
uplinks: {}
packages:
  '**':
    access: \$all
    publish: \$all
listen: 127.0.0.1:$PORT
log: { type: stdout, format: pretty, level: warn }
YAML

echo "==> starting ephemeral registry on $REGISTRY"
npx --yes verdaccio --config "$WORK/config.yaml" >"$WORK/verdaccio.log" 2>&1 &
REG_PID=$!

for _ in $(seq 1 90); do
  if curl -sf "$BASE/-/ping" >/dev/null 2>&1; then break; fi
  if ! kill -0 "$REG_PID" 2>/dev/null; then
    echo "registry exited early; log follows:" >&2; cat "$WORK/verdaccio.log" >&2; exit 1
  fi
  sleep 1
done
curl -sf "$BASE/-/ping" >/dev/null || { echo "registry never became ready" >&2; tail -20 "$WORK/verdaccio.log" >&2; exit 1; }

TOKEN="$(curl -s -X PUT -H 'Content-Type: application/json' \
  -d '{"name":"rehearsal","password":"rehearsal-only"}' \
  "$BASE/-/user/org.couchdb.user:rehearsal" \
  | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>console.log(JSON.parse(d).token))')"

[ -n "$TOKEN" ] && [ "$TOKEN" != "undefined" ] || { echo "could not create a rehearsal user" >&2; exit 1; }

cat > "$WORK/npmrc" <<NPMRC
registry=$REGISTRY
//127.0.0.1:$PORT/:_authToken=$TOKEN
NPMRC

for PKG in "${PACKAGES[@]}"; do
  echo "==> publishing $PKG (rehearsal only, local registry)"
  (cd "$NPM_DIR/$PKG" && npm --userconfig "$WORK/npmrc" publish --registry "$REGISTRY" >"$WORK/publish-$PKG.log" 2>&1) \
    || { echo "publish failed for $PKG:" >&2; tail -20 "$WORK/publish-$PKG.log" >&2; exit 1; }
done

echo "==> installing the published packages as a consumer would"
mkdir -p "$WORK/consumer"
npm --userconfig "$WORK/npmrc" install "${PACKAGES[@]}" \
  --prefix "$WORK/consumer" --registry "$REGISTRY" --no-audit --no-fund --silent

cat > "$WORK/verify.mjs" <<'VERIFY'
import { execFile } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';

const root = process.argv[2];
const pkg = (name) => join(root, 'node_modules', name);
const failures = [];
const check = (label, ok, detail = '') => {
  console.log(`${ok ? '  ok' : '  FAIL'}  ${label}${detail ? ` - ${detail}` : ''}`);
  if (!ok) failures.push(label);
};

// 1. Every package must ship the files its package.json promises. A missing
//    LICENSE here means it was declared in `files` but does not exist on disk.
for (const name of ['easy-onvif-node', 'easy-onvif-web', 'easy-onvif-mcp']) {
  const dir = pkg(name);
  check(`${name}: installed`, existsSync(join(dir, 'package.json')));
  for (const required of ['package.json', 'README.md', 'LICENSE']) {
    check(`${name}: ships ${required}`, existsSync(join(dir, required)));
  }
}

// 2. The MCP server must actually answer over stdio when launched the way an
//    MCP host launches it: through the installed bin entry.
const bin = join(pkg('easy-onvif-mcp'), 'bin', 'easy-onvif-mcp.js');
const handshake = [
  { jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'rehearsal', version: '0' } } },
  { jsonrpc: '2.0', method: 'notifications/initialized' },
  { jsonrpc: '2.0', id: 2, method: 'tools/list' },
].map((m) => JSON.stringify(m)).join('\n') + '\n';

const { stdout, stderr } = await new Promise((resolve, reject) => {
  const child = execFile('node', [bin], { timeout: 60000 }, (err, out, errOut) => {
    if (err && !killed) reject(err);
    resolve({ stdout: out, stderr: errOut });
  });
  let killed = false;
  child.stdout.on('data', (chunk) => {
    if (chunk.toString().includes('"tools"')) { killed = true; child.stdin.end(); child.kill(); }
  });
  child.stdin.write(handshake);
}).catch((e) => ({ stdout: '', stderr: String(e) }));

const replies = stdout.split('\n').filter((l) => l.trim().startsWith('{')).map((l) => JSON.parse(l));
const init = replies.find((r) => r.id === 1);
const list = replies.find((r) => r.id === 2);
check('installed bin completes the MCP handshake', !!init && !!list,
  init && list ? '' : `stdout=${JSON.stringify(stdout).slice(0, 200)} stderr=${stderr.slice(0, 200)}`);
if (init && list) {
  const tools = list.result.tools.map((t) => t.name);
  check('serves the full tool registry', tools.length >= 50, `${tools.length} tools`);
  check('every tool is onvif_-prefixed', tools.every((n) => n.startsWith('onvif_')));
  check('server identity is correct', init.result.serverInfo.name === 'easy-onvif-mcp',
    init.result.serverInfo.name);
}

// 3. The node library bundle must load from its installed location.
try {
  const api = await (await import('file://' + join(pkg('easy-onvif-node'), 'index.mjs'))).loadEasyOnvif();
  check('easy-onvif-node loads and exposes its API', typeof api.connect === 'function' && typeof api.probe === 'function',
    Object.keys(api).length + ' methods');
} catch (e) {
  check('easy-onvif-node loads and exposes its API', false, String(e).slice(0, 200));
}

if (failures.length) {
  console.error(`\nrehearsal FAILED: ${failures.length} problem(s)`);
  process.exit(1);
}
console.log('\nrehearsal passed: all packages publish, install and run.');
VERIFY

echo "==> verifying installed packages"
node "$WORK/verify.mjs" "$WORK/consumer"
