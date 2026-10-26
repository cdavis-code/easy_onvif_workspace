// Packaging check for the browser runtime of `easy-onvif`.
//
// The web loader itself cannot run under Node (it `fetch()`es its own .wasm
// asset and the bundle needs a browser host), so this verifies what a bundler
// would resolve instead: the `./web` subpath maps to a real loader, that loader
// points at artifacts that exist, and the wasm module is intact.
//
// A real in-browser load is exercised manually before an npm release.

import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const pkg = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const manifest = JSON.parse(readFileSync(resolve(pkg, 'package.json'), 'utf8'));

const web = manifest.exports['./web'];
assert.ok(web?.import, './web export missing');
assert.ok(
  existsSync(resolve(pkg, web.import)),
  `./web loader missing: ${web.import}`,
);
assert.ok(
  existsSync(resolve(pkg, web.types)),
  `./web types missing: ${web.types}`,
);

// The loader resolves its assets relative to itself, so the paths it contains
// are the contract with dist/.
const loader = readFileSync(resolve(pkg, web.import), 'utf8');
for (const asset of ['../../dist/web/easy_onvif.wasm', '../../dist/web/easy_onvif.mjs']) {
  assert.ok(loader.includes(asset), `loader does not reference ${asset}`);
  assert.ok(
    existsSync(resolve(dirname(resolve(pkg, web.import)), asset)),
    `missing build artifact for ${asset}`,
  );
}

// dart2wasm output starts with the wasm magic bytes.
const wasm = readFileSync(resolve(pkg, 'dist/web/easy_onvif.wasm'));
assert.equal(wasm.subarray(0, 4).toString('hex'), '0061736d', 'not a wasm module');

// Node must stay reachable through the browser-first conditional export: the
// root entry resolves to the node runtime unless a bundler asks for browser.
const root = manifest.exports['.'];
assert.ok(root.node?.import?.includes('/node/'), 'root node condition broken');
assert.ok(
  root.browser?.import?.includes('/web/'),
  'root browser condition broken',
);

console.log('OK: easy-onvif/web artifacts and export map are consistent.');
