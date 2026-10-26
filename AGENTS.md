# AGENTS.md

This file provides guidance to Qoder (qoder.com) when working with code in this repository.

## Repository overview

Dart monorepo implementing an ONVIF client for IP cameras / NVRs, orchestrated with [Melos](https://melos.invertase.dev/). It publishes Dart packages, two npm packages compiled from Dart, and (via GitHub Release binaries) Homebrew formulas.

| Path | What it is | Published |
| --- | --- | --- |
| `packages/easy_onvif` | Core ONVIF client library (SOAP over HTTP via Dio). Node host bindings are exported from `package:easy_onvif/node.dart` | pub.dev |
| `packages/easy_onvif_cli` | `onvif` command-line executable wrapping the core lib | pub.dev + Homebrew |
| `packages/easy_onvif_js` | JS/WASM interop layer. Owns the single `easy-onvif` npm package (Node + browser runtimes) via `package.json`, `src/`, `dist/`, `test/` | **no** pub (`publish_to: none`); npm |
| `packages/easy_onvif_mcp` | MCP stdio server; tools generated from `@Tool` annotations via `easy_api_generator`. Owns the `easy-onvif-mcp` npm artifact (`package.json`, `bin/easy-onvif-mcp.js`, `dist/`) | pub.dev + npm + Homebrew |
| `packages/easy_onvif_server` | Flutter ONVIF device *simulator* (was root `server/`). Not a Dart workspace member — its `flutter_test` pins a `test_api` incompatible with the workspace | **no** (app) |
| `homebrew/` | Formula templates for the native CLI and MCP binaries | via tap `cdavis-code/homebrew-easy-onvif` |

`easy_onvif` and `easy_onvif_cli` are version-locked together (currently both `3.1.6`).

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

melos run build:npm            # build BOTH npm packages (library then mcp)
melos run build:npm:library    # dart2js + dart2wasm -> packages/easy_onvif_js/dist/{node,web}/
melos run build:npm:mcp        # dart2js -> packages/easy_onvif_mcp/dist/
melos run test:npm:library     # node loader smoke + web artifact/export-map check
melos run test:npm:mcp         # real MCP initialize + tools/list handshake
melos run pack:npm:library     # npm pack --dry-run for the `easy-onvif` package
melos run pack:npm:mcp         # bin-wiring check + npm pack --dry-run

melos run release:npm          # bump/build/commit/tag the easy-onvif npm package
melos run release:npm:mcp      # bump/build/commit/tag the easy-onvif-mcp npm package
melos run publish:npm          # publish both npm packages now, from the working tree
```

Pushing the `easy_onvif_js-v*` / `easy_onvif_mcp-v*` tags triggers CI to publish the
matching npm package (see `dart.yml`). Native binaries and Homebrew are a
separate train: pushing an `onvif-v*` tag runs `native-release.yml`, which then
triggers `homebrew-formula-update.yml` (see the Homebrew section below).

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

- **Two entry points, one npm package:** `lib/entry/node.dart` (compiled with `dart compile js`) and `lib/entry/web.dart` (compiled with `dart compile wasm`). Running a compiled bundle stashes a single API object on `globalThis.EasyOnvif` via `createJSInteropWrapper` on an `@JSExport()` class. Both ship as one `easy-onvif` package with conditional `exports` plus explicit `./node` and `./web` subpaths.
- **Handle registry:** `OnvifApiCore` (`lib/src/api/onvif_api_core.dart`) keeps live `Onvif` instances in a map keyed by opaque integer handles (`registerHandle` / `_requireHandle`). JS callers receive a handle from `connect()` and pass it back to every subsequent method — Dart objects are never passed to JS directly.
- **JSON marshalling:** `_deepJsonify` / `_sanitize` recursively walk Dart model graphs calling `toJson()` before `jsify()`, because `jsify()` does not recurse into opaque Dart objects. They also strip `@`-prefixed XML attribute markers and namespaced keys.
- **Node vs Web:** `NodeOnvifApi` adds `probe()` (WS-Discovery via `node:dgram` through `NodeMulticastProbe`) and overrides `connect()` to inject `NodeFetchAdapter` (Dio over Node's `fetch`, since `XMLHttpRequest` is unavailable in Node). `WebOnvifApi` has no discovery — it throws `UnsupportedError`. Those Node transports now live in the core package (`lib/src/platform/node/`, exported from `package:easy_onvif/node.dart`) so both `easy_onvif_js` and `easy_onvif_mcp` share one copy.
- **Build pipeline:** `tool/build_node.sh` runs `dart compile js` then prepends `tool/node_preamble.js` into `dist/node/`; `tool/build_web.sh` runs `dart compile wasm` into `dist/web/`. Both stage package-local output; there is no root `npm/` staging directory.
- **npm loader:** both npm packages expose `loadEasyOnvif()`. The Node loader uses CommonJS `require` (not `import()`) so the classic-script bundle executes in global scope. **Node ≥25 caveat:** call `loadEasyOnvif()` inside an async IIFE, not from top-level module `await` (breaks the dart2js microtask trampoline / dgram callbacks).

### CLI (`packages/easy_onvif_cli`)

`bin/onvif.dart` builds an `args` `CommandRunner` with one subcommand per ONVIF service (`ptz`, `media1`, `media2`, `device-management`, `recordings`, `replay`, `search`, `imaging`, `probe`, `debug`, `authorize`, `version`). Commands are config-file driven (`--config-file`).

### Flutter simulator (`packages/easy_onvif_server`)

The ONVIF device *simulator* lives under `packages/` for layout only. It is **not**
an `easy_onvif_workspace` member and is excluded from the Melos glob, because
`flutter_test` pins `test_api 0.7.12` which conflicts with the workspace's `test`
constraint. Resolve and test it on its own:

```sh
cd packages/easy_onvif_server
flutter pub get
flutter test
```

## Homebrew

`homebrew/*.rb` are *templates* with `version "0.0.0"` and `*_SHA256` placeholder
tokens. They are not directly installable. The flow is:

1. Push an `onvif-v<semver>` tag (or dispatch `native-release.yml`) → compiles
   `easy-onvif-cli-*` / `easy-onvif-mcp-*` for macOS/Linux/Windows and publishes a
   GitHub Release with `checksums.txt`.
2. `release: published` triggers `homebrew-formula-update.yml`, which copies the
   templates into the `cdavis-code/homebrew-easy-onvif` tap, substitutes the real
   version + per-asset SHA-256, fails if any placeholder survives, then runs
   `ruby -c`, `brew audit --strict` and `brew install`/`brew test` on a clean macOS
   runner.

Prerequisites before the first real run: a `HOMEBREW_TAP_TOKEN` repo secret (a
fine-grained PAT scoped to the tap repo only — the built-in `GITHUB_TOKEN` cannot
write to another repository). Do not advertise `brew install` in user-facing docs
until a release has actually passed the audit job.

## Conventions & gotchas

- **Analysis strictness varies by package.** `easy_onvif` uses `lints/recommended` + `strict-casts`. `easy_onvif_js` is stricter (`strict-casts`, `strict-inference`, `strict-raw-types`), ignores `experimental_member_use` (needed for `dart:js_interop`), and allows `print`. Check a package's `analysis_options.yaml` before assuming a lint applies everywhere.
- **Logging** uses `loggy`. `loggy.error(...)` takes a single string argument — no named parameters.
- **Dependency upgrades are resolvable-only.** Only bump packages to versions that satisfy all existing constraints (e.g., `xml` is held back by `xml2json`). Don't force non-resolvable upgrades without explicit instruction.
- **`@JSExport` methods can't use Dart named-parameter defaults** — dart2js wrappers aren't arity-aware for named args. Use positional nullable params with in-body defaults (see `NodeOnvifApi.probe`).
- **CI** (`.github/workflows/dart.yml`) installs deps with `dart run melos bootstrap` on the stable Flutter/Dart channel, and its `Verify repository layout` step fails if a root `npm/` or `server/` directory reappears or a build surface still references the old `npm/easy-onvif*` staging paths.
- SDK constraint: `>=3.10.0 <4.0.0` (root pins `^3.10.3`).
