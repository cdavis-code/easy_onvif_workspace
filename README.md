# Dart Implementation of ONVIF IP Camera Client

<p align="center" width="100%">
<img src="https://github.com/faithoflifedev/easy_onvif_workspace/blob/main/logo/easy_onvif_logo_640.png?raw=true" width="200" />
</p>

This is the repository for three related Dart packages and two companion npm packages compiled from them (`easy-onvif-node` via `dart2js`, `easy-onvif-web` via `dart2wasm`):

## Dart packages

**[easy_onvif](https://github.com/faithoflifedev/easy_onvif_workspace/tree/main/packages/easy_onvif)** - This package works with a variety of ONVIF compatible devices allowing for IP Cameras and NVRs (network video recorders) to be integrated into Dart and Flutter applications.  The package includes the ability to control the PTZ (pan-tilt-zoom) movements of a device along with managing presets as well as controlling how video and audio is being streamed from the device.  Review the documentation below to get more details on available features.

**[easy_onvif_cli](https://github.com/faithoflifedev/easy_onvif_workspace/tree/main/packages/easy_onvif_cli)** - A command line interface application (`onvif` executable) for controlling an Onvif device through terminal commands.  This tool allows you to use O/S features like `cron` to automate Onvif device functionality.

**[easy_onvif_js](https://github.com/faithoflifedev/easy_onvif_workspace/tree/main/packages/easy_onvif_js)** - JavaScript / WASM interop layer for `easy_onvif`. Not published to pub.dev; it is the build harness that emits the two npm artifacts below — `easy-onvif-node` via `dart compile js` and `easy-onvif-web` via `dart compile wasm` — using `dart:js_interop` for Node-specific transports (`node:dgram` for WS-Discovery).

## npm packages

| npm package | Target | WS-Discovery | Notes |
| --- | --- | --- | --- |
| [`easy-onvif-node`](./npm/easy-onvif-node) | Node.js &ge; 20 | ✅ via `node:dgram` | CLI / server workloads. |
| [`easy-onvif-web`](./npm/easy-onvif-web) | Browsers (WasmGC: Chromium 119+, Firefox 120+, Safari 18.2+) | ❌ rejects with `UnsupportedError` | SOAP over `fetch`; a CORS-friendly proxy is required in front of the camera. |

Both npm packages expose the same `loadEasyOnvif()` ESM entry point and ship full TypeScript declarations (`index.d.ts`).

## Build & release

The repo uses [Melos](https://melos.invertase.dev/) for orchestration. Common scripts:

```sh
# One-time
dart pub get

# Build both npm artifacts (node via dart2js, web via dart2wasm)
melos run build:npm

# Or target one side
melos run build:npm:node
melos run build:npm:web

# Smoke-test the compiled Node bundle (no device required)
melos run smoke:npm:node

# Static analysis across all Dart packages
melos run analyze
```

The build scripts live at
[`packages/easy_onvif_js/tool/`](./packages/easy_onvif_js/tool) and stage the
compiled output into `npm/easy-onvif-node/dist/` (a single dart2js
`easy_onvif.js` bundle) and `npm/easy-onvif-web/dist/` (the dart2wasm
`.wasm` + `.mjs` loader), ready for `npm publish`.
