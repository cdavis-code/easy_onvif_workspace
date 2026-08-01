# AGENTS.md

This file provides guidance to Qoder (qoder.com) when working with code in this repository.

## Repository overview

Dart monorepo implementing an ONVIF client for IP cameras / NVRs, orchestrated with [Melos](https://melos.invertase.dev/). It produces three Dart packages and two npm packages compiled from Dart:

| Path | What it is | Published |
| --- | --- | --- |
| `packages/easy_onvif` | Core ONVIF client library (SOAP over HTTP via Dio) | pub.dev |
| `packages/easy_onvif_cli` | `onvif` command-line executable wrapping the core lib | pub.dev |
| `packages/easy_onvif_js` | JS/WASM interop layer; build harness for the npm artifacts | **no** (`publish_to: none`) |
| `npm/easy-onvif-node` | Node.js ≥20 npm artifact (dart2js), WS-Discovery via `node:dgram` | npm |
| `npm/easy-onvif-web` | Browser npm artifact (dart2wasm/WasmGC), no discovery | npm |

`easy_onvif` and `easy_onvif_cli` are version-locked together (currently both `3.1.4`).

## Workspace setup

This is a native Dart workspace: the root `pubspec.yaml` declares a `workspace:` key and each package sets `resolution: workspace`. Resolve dependencies from the **root**:

```sh
dart pub get                 # resolves the whole workspace
# or (what CI uses):
dart run melos bootstrap
```

Do not run `dart pub get` inside individual packages for routine setup; resolve from the root so the workspace lockfile stays consistent.

## Common commands

Run Melos scripts from the repo root:

```sh
melos run analyze            # dart analyze across all packages
melos run format             # dart format all packages
melos run format-check       # format check (fails if changes needed)
melos run lint:all           # analyze + format

melos run build:npm          # build BOTH npm artifacts (node then web)
melos run build:npm:node     # dart2js  -> npm/easy-onvif-node/dist/
melos run build:npm:web      # dart2wasm -> npm/easy-onvif-web/dist/
melos run smoke:npm:node     # smoke-test compiled Node bundle (no device needed)
```

### Code generation (json_serializable)

`easy_onvif` models use `json_serializable`; `.g.dart` files are committed. After editing any model, regenerate from within that package (build_runner is only a dependency there):

```sh
cd packages/easy_onvif
dart run build_runner build --delete-conflicting-outputs
```

Generated `*.g.dart` files are excluded from analysis.

### Tests

Tests live in `packages/easy_onvif/test/` and use `package:test`:

```sh
cd packages/easy_onvif
dart test                              # all tests
dart test test/ptz_test.dart           # a single file
dart test --name "AbsoluteMoveResponse"  # tests matching a name
```

> **Caveat:** the fixture-based tests read XML from `../../test_data/xml/...` (relative to the package root), a directory that is **not part of this repository**. Those tests will fail unless an external `test_data` fixture checkout exists at that location. Don't treat fixture-file failures as regressions in the library code.

### Running the CLI during development

```sh
cd packages/easy_onvif_cli
dart run bin/onvif.dart <command>      # e.g. ptz, media1, device-management, probe
```

## Architecture

### Core library (`packages/easy_onvif`)

- **Entry point:** `Onvif` (`lib/src/onvif_base.dart`). Use `Onvif.connect(host, username, password)`. The constructor wires up a `Dio` instance and a SOAP `Transport`, then `initialize()` discovers available services.
- **Service discovery flow:** `initialize()` computes a clock `timeDelta`, calls `deviceManagement.getServices()` to build a `serviceMap` (XML namespace → service URL), and instantiates one client per supported service: `DeviceManagement`, `Imaging`, `Ptz`, `Recordings`, `Replay`, `Search`, and `Media`. If `GetServices` isn't supported, it falls back to `getCapabilities()`. Accessing a service that wasn't discovered throws.
- **`Media` is a facade** over `Media1` (ver10) and `Media2` (ver20); both may be populated depending on device support.
- **SOAP layer** (`lib/src/soap/`): `Transport` POSTs XML envelopes via Dio with `application/soap+xml`. `getSecuredEnvelope()` adds a WS-Security `UsernameToken` (nonce + created timestamp derived from `Transport.timeDelta`, which compensates for device clock skew). Digest auth helpers live in `authorization.dart` / `nonce.dart`.
- **Models** (`lib/src/model/`): XML responses are converted to JSON maps (`OnvifUtil.xmlToMap`, via `xml2json`) then deserialized with `json_serializable` `fromJson`. Each ONVIF service has its own model subdirectory.
- **Platform abstraction** (`lib/src/platform/`): conditional `io` / `web` / `stub` implementations for WS-Discovery multicast probing, environment variables, and MTOM parsing. This is what lets the same core compile for VM, browser, and Node.

### JS interop layer (`packages/easy_onvif_js`)

- **Two entry points:** `lib/entry/node.dart` (compiled with `dart compile js`) and `lib/entry/web.dart` (compiled with `dart compile wasm`). Running the compiled bundle stashes a single API object on `globalThis.EasyOnvif` via `createJSInteropWrapper` on an `@JSExport()` class.
- **Handle registry:** `OnvifApiCore` (`lib/src/api/onvif_api_core.dart`) keeps live `Onvif` instances in a map keyed by opaque integer handles (`registerHandle` / `_requireHandle`). JS callers receive a handle from `connect()` and pass it back to every subsequent method — Dart objects are never passed to JS directly.
- **JSON marshalling:** `_deepJsonify` / `_sanitize` recursively walk Dart model graphs calling `toJson()` before `jsify()`, because `jsify()` does not recurse into opaque Dart objects. They also strip `@`-prefixed XML attribute markers and namespaced keys.
- **Node vs Web:** `NodeOnvifApi` adds `probe()` (WS-Discovery via `node:dgram` through `NodeMulticastProbe`) and overrides `connect()` to inject `NodeFetchAdapter` (Dio over Node's `fetch`, since `XMLHttpRequest` is unavailable in Node). `WebOnvifApi` has no discovery — it throws `UnsupportedError`.
- **Build pipeline:** `tool/build_node.sh` runs `dart compile js -O2` then prepends `tool/node_preamble.js`; `tool/build_web.sh` runs `dart compile wasm -O2`. Both stage output into `npm/*/dist/`.
- **npm loader:** both npm packages expose `loadEasyOnvif()`. The Node loader uses CommonJS `require` (not `import()`) so the classic-script bundle executes in global scope. **Node ≥25 caveat:** call `loadEasyOnvif()` inside an async IIFE, not from top-level module `await` (breaks the dart2js microtask trampoline / dgram callbacks).

### CLI (`packages/easy_onvif_cli`)

`bin/onvif.dart` builds an `args` `CommandRunner` with one subcommand per ONVIF service (`ptz`, `media1`, `media2`, `device-management`, `recordings`, `replay`, `search`, `imaging`, `probe`, `debug`, `authorize`, `version`). Commands are config-file driven (`--config-file`).

## Conventions & gotchas

- **Analysis strictness varies by package.** `easy_onvif` uses `lints/recommended` + `strict-casts`. `easy_onvif_js` is stricter (`strict-casts`, `strict-inference`, `strict-raw-types`), ignores `experimental_member_use` (needed for `dart:js_interop`), and allows `print`. Check a package's `analysis_options.yaml` before assuming a lint applies everywhere.
- **Logging** uses `loggy`. `loggy.error(...)` takes a single string argument — no named parameters.
- **Dependency upgrades are resolvable-only.** Only bump packages to versions that satisfy all existing constraints (e.g., `xml` is held back by `xml2json`). Don't force non-resolvable upgrades without explicit instruction.
- **`@JSExport` methods can't use Dart named-parameter defaults** — dart2js wrappers aren't arity-aware for named args. Use positional nullable params with in-body defaults (see `NodeOnvifApi.probe`).
- **CI** (`.github/workflows/dart.yml`) installs deps with `dart run melos bootstrap` on the stable Flutter/Dart channel.
- SDK constraint: `>=3.10.0 <4.0.0` (root pins `^3.10.3`).
