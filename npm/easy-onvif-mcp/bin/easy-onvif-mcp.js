#!/usr/bin/env node
// Node.js entry point for the easy-onvif-mcp stdio server.
//
// `dist/easy_onvif_mcp.runtime.js` is the `dart compile js` output of
// `packages/easy_onvif_mcp_js`, which targets a browser host. Before it can
// serve JSON-RPC over stdio under Node.js it needs:
//
//   1. `self` and `window` on globalThis. dart2js reads both at startup; the
//      absence of either throws inside the async stream machinery, and because
//      dart_mcp swallows peer-sink errors that failure shows up as a server
//      that silently never replies.
//   2. `globalThis.require`. WS-Discovery (`onvif_probe`) loads `node:dgram`
//      through `globalThis.require`, which an ES-module context does not
//      provide — so it is created here from this module's URL.
//   3. A handle keeping the event loop alive. The Dart side only attaches
//      stdin listeners; without a timer Node exits as soon as stdin pauses.
//
// The runtime is loaded from inside an async IIFE rather than with top-level
// await: top-level await in an ES module breaks the dart2js microtask
// trampoline on Node >= 25 (see AGENTS.md).
//
// This file is hand-maintained. `tool/build_mcp_node.sh` regenerates only the
// dist runtime — do not let it overwrite this wrapper.

import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// ---------------------------------------------------------------------------
// 1. Browser globals the compiled bundle expects
// ---------------------------------------------------------------------------
const globals = globalThis;
if (typeof globals.self === 'undefined') globals.self = globals;
if (typeof globals.window === 'undefined') globals.window = globals;

// ---------------------------------------------------------------------------
// 2. require(), for node:dgram used by the discovery probe
// ---------------------------------------------------------------------------
if (typeof globals.require === 'undefined') {
  globals.require = createRequire(import.meta.url);
}

// ---------------------------------------------------------------------------
// 3. Keep the event loop alive until the MCP host disconnects
// ---------------------------------------------------------------------------
const keepAlive = setInterval(() => {}, 1 << 30);

const shutdown = (code = 0) => {
  clearInterval(keepAlive);
  process.exit(code);
};

process.on('SIGINT', () => shutdown(130));
process.on('SIGTERM', () => shutdown(143));
process.stdin.on('end', () => shutdown(0));
process.stdin.on('close', () => shutdown(0));

// ---------------------------------------------------------------------------
// 4. Boot the Dart server (its main() attaches the stdio transport)
// ---------------------------------------------------------------------------
const here = dirname(fileURLToPath(import.meta.url));
const runtime = resolve(here, '../dist/easy_onvif_mcp.runtime.js');

(async () => {
  await import(runtime);
})();
