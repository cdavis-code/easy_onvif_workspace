# easy-onvif-node

[ONVIF](https://www.onvif.org/) client for Node.js, compiled from the Dart
[`easy_onvif`](https://pub.dev/packages/easy_onvif) package with `dart2js`.
Supports **WS-Discovery** over UDP multicast (via `node:dgram`) plus a full
service-object API mirroring the underlying Dart package:
`deviceManagement`, `media`, `ptz`, `imaging`, `search`, `recordings`,
`replay`.

> For the browser build see
> [`easy-onvif-web`](https://www.npmjs.com/package/easy-onvif-web).

## Requirements

- Node.js **20+**

## Install

```sh
npm install easy-onvif-node
```

## Quick start

```js
import { loadEasyOnvif } from 'easy-onvif-node';

(async () => {
  const onvif = await loadEasyOnvif();

  // Discover devices on the local network.
  const matches = await onvif.probe(2);
  console.log(matches);

  // Connect to a known camera; returns an opaque numeric handle.
  const handle = await onvif.connect({
    host: '192.168.1.64:8000',
    username: 'admin',
    password: 'secret',
  });

  // Grab a service proxy for each SOAP area you need.
  const deviceMgmt = onvif.getDeviceManagement(handle);
  const media      = onvif.getMedia(handle);
  const ptz        = onvif.getPtz(handle);

  const info = await deviceMgmt.getDeviceInformation();
  console.log(info);

  const [profile] = await media.getProfiles();
  console.log(await media.getStreamUri(profile.token));
  console.log(await media.getSnapshotUri(profile.token));

  const status = await ptz.getStatus(profile.token);
  console.log(status);

  onvif.disconnect(handle);
})();
```

> **Note:** Call `loadEasyOnvif()` from inside an async function / IIFE —
> not from a top-level `await` — so dart2js's microtask trampoline keeps
> servicing `dgram` callbacks on Node 25+.

## API

See [`index.d.ts`](./index.d.ts) for full TypeScript definitions.

### Top-level API

| Method | Purpose |
| --- | --- |
| `loadEasyOnvif()` | Lazily loads the compiled bundle and returns the API. |
| `connect({ host, username, password })` | SOAP bootstrap; returns an integer handle. |
| `disconnect(handle)` | Frees the handle. Idempotent. |
| `probe(timeoutSeconds = 2)` | WS-Discovery over UDP multicast (Node-only). |
| `getDeviceManagement(handle)` | Returns a `DeviceManagementService` proxy. |
| `getMedia(handle)` | Returns a `MediaService` proxy. |
| `getPtz(handle)` | Returns a `PtzService` proxy. |
| `getImaging(handle)` | Returns an `ImagingService` proxy. |
| `getSearch(handle)` | Returns a `SearchService` proxy. |
| `getRecordings(handle)` | Returns a `RecordingsService` proxy. |
| `getReplay(handle)` | Returns a `ReplayService` proxy. |

### `deviceManagement`

| Method | Purpose |
| --- | --- |
| `getDeviceInformation()` | Manufacturer / model / firmware / serial. |
| `getServices(includeCapability?)` | All ONVIF services advertised by the device. |
| `getServiceCapabilities()` | Device-service capability descriptor. |
| `getCapabilities()` | Legacy aggregate capability descriptor. |
| `getSystemDateAndTime()` | Current device date/time and timezone. |
| `getHostname()` | Hostname configuration. |
| `getDns()` | DNS configuration. |
| `getNtp()` | NTP configuration. |
| `getNetworkProtocols()` | Enabled network protocols. |
| `getDiscoveryMode()` | Discovery mode (`Discoverable` / `NonDiscoverable`). |
| `getUsers()` | Registered users. |
| `createUsers(users)` | Adds users. |
| `deleteUsers(usernames)` | Removes users. |
| `systemReboot()` | Reboots the device. |
| `getDynamicDns()` | Dynamic DNS settings. |
| `getIPAddressFilter()` | IP-address filter rules. |
| `getStorageConfigurations()` | All storage configurations. |
| `getStorageConfiguration(referenceToken)` | A specific storage configuration. |
| `getEndpointReference()` | Endpoint-reference address. |
| `getSystemUris()` | URIs for system logs / support info / backup. |

### `media`

| Method | Purpose |
| --- | --- |
| `getProfiles()` | Media profile list. |
| `getProfile(token)` | Single profile by token. |
| `getStreamUri(profileToken)` | RTSP stream URI. |
| `getSnapshotUri(profileToken)` | HTTP snapshot URI. |
| `getVideoSources()` | Physical video inputs. |
| `getAudioSources()` | Physical audio inputs. |
| `getServiceCapabilities()` | Media-service capability descriptor. |
| `startMulticastStreaming(profileToken)` | Start multicast for a profile. |
| `stopMulticastStreaming(profileToken)` | Stop multicast for a profile. |

### `ptz`

| Method | Purpose |
| --- | --- |
| `absoluteMove(profileToken, x, y, zoom)` | Absolute pan / tilt / zoom. |
| `relativeMove(profileToken, x, y, zoom, speedX?, speedY?, speedZoom?)` | Relative pan / tilt / zoom. |
| `continuousMove(profileToken, vx, vy, vzoom, timeout?)` | Continuous velocity move. |
| `stop(profileToken, panTilt?, zoom?)` | Stop current movement. |
| `getStatus(profileToken)` | Current PTZ position / move state. |
| `getPresets(profileToken)` | All saved presets. |
| `gotoPreset(profileToken, presetToken)` | Move to a preset. |
| `setPreset(profileToken, presetName?, presetToken?)` | Save the current position as a preset. |
| `removePreset(profileToken, presetToken)` | Delete a preset. |
| `gotoHomePosition(profileToken)` | Move to the home position. |
| `setHomePosition(profileToken)` | Save the current position as home. |
| `getConfigurations()` | All PTZ configurations. |
| `getConfiguration(configurationToken)` | A specific PTZ configuration. |
| `getConfigurationOptions(configurationToken)` | Options for a configuration. |
| `getCompatibleConfigurations(profileToken)` | Configurations compatible with a profile. |
| `getPresetTours(profileToken)` | All preset tours. |
| `getPresetTour(profileToken, presetTourToken)` | A specific preset tour. |
| `getServiceCapabilities()` | PTZ-service capability descriptor. |

### `imaging`

| Method | Purpose |
| --- | --- |
| `getCurrentPreset(videoSourceToken)` | Currently applied imaging preset. |
| `getPresets(videoSourceToken)` | Available imaging presets. |
| `getStatus(videoSourceToken)` | Current imaging status (focus, etc.). |
| `setCurrentPreset(videoSourceToken, presetToken)` | Apply an imaging preset. |
| `getServiceCapabilities()` | Imaging-service capability descriptor. |

### `search`

| Method | Purpose |
| --- | --- |
| `findRecordings(keepAliveTime?)` | Start a recording search; returns a search token. |
| `getRecordingSearchResults(searchToken)` | Fetch results from a search session. |
| `getRecordingInformation(recordingToken)` | Metadata for a specific recording. |
| `getRecordingSummary()` | Aggregate recording summary. |

### `recordings`

| Method | Purpose |
| --- | --- |
| `getRecordings()` | All recordings on the device. |
| `getServiceCapabilities()` | Recordings-service capability descriptor. |

### `replay`

| Method | Purpose |
| --- | --- |
| `getReplayConfiguration()` | Current replay configuration. |
| `getReplayUri(recordingToken)` | URI for replaying a recording. |
| `getServiceCapabilities()` | Replay-service capability descriptor. |

## How it's built

Source lives in the
[`easy_onvif_js`](https://github.com/faithoflifedev/easy_onvif_workspace/tree/main/packages/easy_onvif_js)
Dart workspace package. Build pipeline:

```sh
# From the repo root
cd packages/easy_onvif_js
bash tool/build_node.sh         # produces dist/easy_onvif.js
node tool/smoke_test_node.mjs   # sanity check
```

`build_node.sh` invokes `dart compile js -O2` on
[`lib/entry/node.dart`](https://github.com/faithoflifedev/easy_onvif_workspace/blob/main/packages/easy_onvif_js/lib/entry/node.dart),
prepends a Node preamble, and stages the result as
`npm/easy-onvif-node/dist/easy_onvif.js`. The compiled bundle publishes
`globalThis.EasyOnvif`, which the loader shim in
[`index.mjs`](./index.mjs) returns.

Node-only interop (WS-Discovery `dgram` bindings and a `fetch`-based Dio
HTTP adapter) lives alongside the service factories and is exposed through
[`dart:js_interop`](https://api.dart.dev/stable/dart-js_interop/dart-js_interop-library.html).

## License

MIT
