# In-App Settings Design

Move the ONVIF server app's configuration from `~/.easy_onvif_server/settings.yaml`
to an in-app settings UI (gear icon in the appbar), persisted as JSON inside the
app's own sandbox container. The external YAML file, the bundled asset fallback,
and the macOS sandbox entitlement exception are all removed.

## Decisions

| Question | Decision |
| --- | --- |
| Persistence | JSON file in `getApplicationSupportDirectory()` via `path_provider` |
| UI scope | Full `ServerSettings` schema, sectioned UI, enumerated pickers via capability discovery |
| Migration | Clean break — existing `settings.yaml` ignored, all YAML loading code removed |
| Apply model | Saving while the server is running stops and restarts it with the new settings |
| Architecture | Settings screen route + explicit Save editing a draft copy (no new state-management dependency) |

## Motivation

- macOS App Sandbox made `existsSync()` on `~/.easy_onvif_server/settings.yaml`
  silently return false, so overrides were invisibly ignored until a
  `temporary-exception.files.home-relative-path.read-only` entitlement was added.
  In-app storage eliminates that entitlement and the whole invisible-failure class.
- Settings changes currently require hand-editing YAML plus an app restart; the
  UI makes them discoverable and applies them on save.
- Toggling audio in the UI gives a deterministic, user-gesture-driven point to
  request microphone access (better TCC prompt diagnostics), though fixing the
  TCC attribution bug itself is out of scope.

## Section 1: Data layer — model + persistence

Model changes in `server/lib/src/settings.dart`:

- `ServerSettings`, `ServiceFlags`, `ImagingPresetSetting`, `MediaSettings` gain
  `toJson()` / `fromJson()`. The JSON schema mirrors the class structure with the
  same nested sections as the old YAML (`device`, `network`, `auth`, `services`,
  `recording`, `imaging`, `geolocation`, `media`) so the file stays readable.
- `copyWith(...)` added where the UI needs field-level edits; classes stay
  immutable — the settings screen edits a draft via `copyWith`.
- Deleted: `ServerSettings.load()`, `ServerSettings.parse()` (YAML), the `yaml`
  import, `assets/settings.yaml`, and its pubspec asset entry. The `yaml`
  dependency is removed if nothing else in the server uses it.

New `server/lib/src/settings_store.dart`:

- `SettingsStore` with `Future<ServerSettings> load()` / `Future<void> save(ServerSettings)`.
- Path: `<Application Support>/settings.json` via `path_provider` (injectable
  directory for tests). No entitlement needed inside the sandbox container.
- `load()`: missing or unparseable file → `const ServerSettings()` defaults
  (corrupt file never blocks startup; it is overwritten on next save).
- `save()`: pretty-printed JSON, atomic write (temp file + rename).

Entitlements: remove the `temporary-exception.files.home-relative-path.read-only`
block from `DebugProfile.entitlements` and `Release.entitlements`.

## Section 2: Settings screen + capability discovery

New `server/lib/src/ui/settings_screen.dart` — a `StatefulWidget` pushed from a
gear `IconButton` in the appbar. It receives the current `ServerSettings`, edits
a draft copy via `copyWith`, and returns the saved result (null on cancel)
through `Navigator.pop`.

Layout: a single scrollable `ListView` with section headers:

- **Device**: manufacturer, model, firmware, serial, hardware ID, hostname (text fields)
- **Network**: HTTP port, RTSP port (numeric, 1–65535 validation)
- **Auth**: username, password (obscured with reveal toggle)
- **Media**: video source (`SegmentedButton`: Camera / Display / Test), video
  device (discovery-populated dropdown, "System default" first), audio enable
  (switch), audio device (dropdown, enabled only when audio is on)
- **Services**: recording / replay / search / imaging switches
- **Recording**: directory (blank = platform temp), segment seconds, retention
  minutes (blank = keep forever)
- **Imaging**: editable preset list (add/remove rows: token, name, type)
- **Location**: lat / lon / elevation (blank = no fallback)

Capability discovery on screen open (spinners until loaded):

- Cameras: `availableCameras()` → names/IDs
- Audio inputs (macOS): new `listAudioDevices` method on the existing
  `audio_capture` channel returning `[{uid, name}]`, backed by the CoreAudio
  enumeration already in `AudioCaptureSource.swift`
- Displays (macOS): new `listDisplays` method on the `screen_capture` channel
  returning `[{id, name}]`
- Non-macOS or discovery failure: plain text field fallback, nothing blocks

Save validates ports/numbers, persists via `SettingsStore`, and pops.

## Section 3: Main screen wiring + apply-on-save

- Startup: settings load once in `initState` via `SettingsStore.load()` into
  `_settings`. `_start()` drops the `rootBundle` + `ServerSettings.load` pair and
  uses `_settings`; `_ensurePermissions`, `_createStreamBackend`, and
  `OnvifDevice` are untouched.
- Appbar: gear `IconButton`, enabled always but disabled while `_busy`.
- Apply on save: settings screen pops with the saved result →
  `setState(() => _settings = result)`; if the server is running, stop then
  start (nulling the camera controller before `device.stop()`, per the
  established dispose-race pattern). Snackbar reports "Settings saved — server
  restarted" vs "Settings saved".
- Microphone prompt: toggling audio ON in the settings screen immediately fires
  `requestMicrophone` on the permissions channel from that user gesture. Denied
  → inline warning with an "Open System Settings" hint. `_ensurePermissions` at
  start stays as a backstop.

## Section 4: Cleanup, tests, non-goals

Dependency added: `path_provider` (server only).

Tests:

- `settings_test.dart` rewritten: JSON round-trip for every section (defaults,
  full custom values, unknown keys ignored, malformed values throw
  `FormatException` mirroring today's coercion rules)
- New `settings_store_test.dart`: missing file → defaults; save/load round-trip;
  corrupt file → defaults; atomic write leaves no temp files (injectable
  directory, no platform channels)
- Integration tests using `ServerSettings.parse(yaml)` migrate to the
  constructor / `fromJson`; behavior assertions unchanged
- One settings-screen widget test: draft-edit → save returns updated settings;
  port validation blocks bad input

Non-goals: live reconfiguration without restart, settings sync/export, fixing
the TCC microphone-prompt attribution bug itself, CLI/headless overrides.

