# easy_onvif_mcp_js

[`easy_onvif_mcp`](../easy_onvif_mcp) compiled with `dart compile js` so it can
ship as the [`easy-onvif-mcp`](../../npm/easy-onvif-mcp) npm package and run
under `npx`.

This package holds *only* the Node.js host adapter. The server, the protocol
handling and every tool live in `easy_onvif_mcp` and are reused unchanged:
`easy_onvif_mcp` is deliberately `dart:io`-free, and this package supplies the
one implementation of its `McpRuntime` seam that a compiled JS process needs.

## Layout

| Path | What it is |
| --- | --- |
| `lib/easy_onvif_mcp_js.dart` | entry point compiled by `dart compile js` |
| `lib/src/runtime_node.dart` | `McpRuntime` for Node: stdio framing, `NodeFetchAdapter` Dio, `node:dgram` discovery, `process.env` |
| `lib/src/node_interop.dart` | the `dart:js_interop` bindings for `process` / `console` |
| `tool/build_mcp_node.sh` | compiles and stages the runtime into `npm/easy-onvif-mcp/dist/` |
| `tool/publish_npm.sh` | version bump → build → commit → tag, which triggers the npm publish workflow |

## Why a Node runtime is needed at all

`dart compile js` emits code that assumes a browser host, and three things do
not exist under Node.js:

1. **`XMLHttpRequest`** — Dio's compiled default HTTP adapter. SOAP requests are
   routed through `NodeFetchAdapter` (Node's global `fetch`) instead, the same
   approach `easy-onvif-node` uses.
2. **`globalThis.require`** — WS-Discovery needs `node:dgram`, which ES modules
   do not expose. The npm wrapper creates it with `createRequire`.
3. **`self` / `window`** — read at startup by the compiled runtime; their
   absence throws inside the async stream machinery, and because `dart_mcp`
   swallows peer-sink errors the server would look alive while never replying.

## Building

```sh
# from the repo root
melos run build:npm:mcp
```

The current bundle is **590 KB** (`dist/easy_onvif_mcp.runtime.js`, 17 MB of Dart
input compiled at `-O4`). The library-only build is 517 KB, so `dart_mcp` plus
the protocol plumbing and the 52 tool schemas cost roughly 72 KB on top. Chunk
splitting and deferred loading are not options — the npm package loads one
classic script.

Source maps are deliberately not published.

Then verify the handshake without a camera:

```sh
npm test --prefix npm/easy-onvif-mcp
```

## Releasing

```sh
bash packages/easy_onvif_mcp_js/tool/publish_npm.sh patch
git push origin main --tags    # CI publishes to npm
```

`publish_to: none` — this package is never published to pub.dev; its output is
the npm artifact.
