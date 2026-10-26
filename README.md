# Dart Implementation of ONVIF IP Camera Client

<p align="center" width="100%">
<img src="https://github.com/cdavis-code/easy_onvif_workspace/blob/main/logo/easy_onvif_logo_640.png?raw=true" width="200" />
</p>

This is the repository for the ONVIF Dart stack: the core client library, a CLI, an
MCP server, a JavaScript/WASM interop layer, and a Flutter device simulator. From
them we publish Dart packages, two npm packages (`easy-onvif`, `easy-onvif-mcp`),
and native binaries distributed through a Homebrew tap.

## Dart packages

**[easy_onvif](https://github.com/cdavis-code/easy_onvif_workspace/tree/main/packages/easy_onvif)** - This package works with a variety of ONVIF compatible devices allowing for IP Cameras and NVRs (network video recorders) to be integrated into Dart and Flutter applications.  The package includes the ability to control the PTZ (pan-tilt-zoom) movements of a device along with managing presets as well as controlling how video and audio is being streamed from the device.  Review the documentation below to get more details on available features.

**[easy_onvif_cli](https://github.com/cdavis-code/easy_onvif_workspace/tree/main/packages/easy_onvif_cli)** - A command line interface application (`onvif` executable) for controlling an Onvif device through terminal commands.  This tool allows you to use O/S features like `cron` to automate Onvif device functionality.

**[easy_onvif_mcp](https://github.com/cdavis-code/easy_onvif_workspace/tree/main/packages/easy_onvif_mcp)** - An MCP (Model Context Protocol) stdio server exposing device, media, PTZ, imaging, recording and discovery tools, so a model can drive a camera directly.

**[easy_onvif_js](https://github.com/cdavis-code/easy_onvif_workspace/tree/main/packages/easy_onvif_js)** - JavaScript / WASM interop layer for `easy_onvif`. Not published to pub.dev; it owns the `easy-onvif` npm package, emitting the Node runtime via `dart compile js` and the browser runtime via `dart compile wasm`, using `dart:js_interop` for Node-specific transports (`node:dgram` for WS-Discovery).

**[easy_onvif_server](https://github.com/cdavis-code/easy_onvif_workspace/tree/main/packages/easy_onvif_server)** - A Flutter application that acts as an ONVIF *device* (camera/NVR simulator), serving the SOAP API the client consumes and exposing the host camera, microphone and hardware. Used for development and integration testing.

## npm packages

| npm package | Target | WS-Discovery | Notes |
| --- | --- | --- | --- |
| [`easy-onvif`](https://www.npmjs.com/package/easy-onvif) | Node.js &ge; 20 (`easy-onvif/node`) and browsers — WasmGC: Chromium 119+, Firefox 120+, Safari 18.2+ (`easy-onvif/web`) | Node ✅ via `node:dgram`; browser ❌ rejects with `UnsupportedError` | One package, two runtimes behind conditional `exports`. Browser SOAP needs a CORS-friendly proxy in front of the camera. |
| [`easy-onvif-mcp`](https://www.npmjs.com/package/easy-onvif-mcp) | Node.js &ge; 20 (stdio MCP server) | ✅ | `npx -y easy-onvif-mcp`. See [easy_onvif_mcp](https://pub.dev/packages/easy_onvif_mcp). |

Both entry points expose the same `loadEasyOnvif()` API and ship full TypeScript declarations. Import the explicit `easy-onvif/node` or `easy-onvif/web` subpath (or the root, which resolves per-platform) rather than relying on a bundler's condition handling.

> **Migration:** `easy-onvif` replaces the former `easy-onvif-node` and
> `easy-onvif-web` packages. Change `from 'easy-onvif-node'` to
> `from 'easy-onvif/node'` and `from 'easy-onvif-web'` to `from 'easy-onvif/web'`;
> the runtime behavior and Node &ge; 25 `loadEasyOnvif()` caveats are unchanged.

## Homebrew

The native CLI and MCP binaries are distributed as a Homebrew tap
(`cdavis-code/homebrew-easy-onvif`), built by `native-release.yml` and kept in sync
by `homebrew-formula-update.yml`. This becomes available once the first `onvif-v*`
native release has run and passed the tap's audit job:

```sh
brew tap cdavis-code/easy-onvif
brew install easy-onvif-cli easy-onvif-mcp   # after the first native release
```

Formulas install prebuilt GitHub Release binaries (macOS ARM64/x64, Linux
ARM64/x64). The `homebrew/` directory holds the templates; `brew install` is only
available once a release has been published.

## Build & release

The repo uses [Melos](https://melos.invertase.dev/) for orchestration. Common scripts:

```sh
# One-time (resolves the whole Dart workspace from the repo root)
dart pub get

# Build both npm packages (library then mcp)
melos run build:npm

# Or one side
melos run build:npm:library   # -> packages/easy_onvif_js/dist/{node,web}/
melos run build:npm:mcp       # -> packages/easy_onvif_mcp/dist/

# Test / inspect what would be published
melos run test:npm:library
melos run test:npm:mcp
melos run pack:npm:library
melos run pack:npm:mcp

# Static analysis across all Dart packages
melos run analyze
```

The Flutter simulator is resolved separately (`cd packages/easy_onvif_server &&
flutter test`); it is not a Dart workspace member. The build scripts live under
each owning package (`packages/easy_onvif_js/tool/`, `packages/easy_onvif_mcp/tool/`)
and stage package-local output — there is no root `npm/` staging tree.
