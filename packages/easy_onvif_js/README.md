# JavaScript Bindings for easy_onvif

<p align="center" width="100%">
<img src="https://github.com/faithoflifedev/easy_onvif/blob/main/logo/easy_onvif_logo_640.png?raw=true" width="200" />
</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/faithoflifedev/easy_onvif/blob/main/LICENSE)

This package is the JavaScript interop layer for the pure-Dart
[`easy_onvif`](https://pub.dev/packages/easy_onvif) ONVIF client. It compiles
with **`dart compile js` (dart2js)** to produce two npm artifacts that expose
the same operations — device management, media streaming, PTZ control, imaging,
recording, replay and search — to Node.js and browser applications.

| npm package | Target | Discovery | Notes |
|---|---|---|---|
| [`easy-onvif-node`](https://www.npmjs.com/package/easy-onvif-node) | Node.js ≥ 20 | ✅ WS-Discovery via `node:dgram` | CLI / server workloads |
| [`easy-onvif-web`](https://www.npmjs.com/package/easy-onvif-web) | Browsers (modern ESM) | ❌ `UnsupportedError` | SOAP-over-`fetch` only; CORS proxy required |

This package is **not published to pub.dev**. It is a build harness that
consumes the pure-Dart `easy_onvif` package and emits a JavaScript bundle
wrapped with hand-written ESM loaders and TypeScript declarations.

## Table of contents

- [JavaScript Bindings for easy_onvif](#javascript-bindings-for-easy_onvif)
  - [Table of contents](#table-of-contents)
  - [Getting Started](#getting-started)
    - [Dependency](#dependency)
    - [Usage Example](#usage-example)
    - [Interacting with a device through Onvif operations](#interacting-with-a-device-through-onvif-operations)
  - [Build](#build)
  - [Smoke test (Node)](#smoke-test-node)
  - [Supported Onvif Operations](#supported-onvif-operations)
    - [Device Management](#device-management)
    - [Media](#media)
    - [PTZ](#ptz)
    - [Imaging](#imaging)
    - [Recordings](#recordings)
    - [Replay](#replay)
    - [Search](#search)
  - [Onvif Probe](#onvif-probe)
  - [Known limitations](#known-limitations)
  - [Features and bugs](#features-and-bugs)
  - [Contributing](#contributing)

## Getting Started

### Dependency

Install the appropriate npm package depending on your target:

```sh
# Node.js
npm install easy-onvif-node

# Browser (bundled with webpack / vite / rollup)
npm install easy-onvif-web
```

### Usage Example

Import the loader, connect to a device, and grab service proxies through the
returned handle.

```js
import { loadEasyOnvif } from 'easy-onvif-node';

const onvif = await loadEasyOnvif();

const handle = await onvif.connect({
  host: '192.168.1.100',
  username: 'admin',
  password: 'password',
});

const deviceManagement = onvif.getDeviceManagement(handle);
const media            = onvif.getMedia(handle);
const ptz              = onvif.getPtz(handle);
const imaging          = onvif.getImaging(handle);
const search           = onvif.getSearch(handle);
const recordings       = onvif.getRecordings(handle);
const replay           = onvif.getReplay(handle);
```

### Interacting with a device through Onvif operations

Like the underlying Dart package, every Onvif command has an associated
`Access Policy`. Authenticate as `Administrator` to avoid permission errors.
See the [access-policy table in the Dart README](https://github.com/faithoflifedev/easy_onvif/blob/main/packages/easy_onvif/README.md#interacting-with-a-device-through-onvif-operations).

Through the `deviceManagement` proxy you can get information about the
connected device.

```js
const info = await deviceManagement.getDeviceInformation(); // READ_SYSTEM
console.log(info.model);
```

Many operations require a `profileToken`, retrievable through `media`.

```js
const profiles = await media.getProfiles(); // READ_MEDIA
profiles.forEach(p => console.log(`${p.name}  ${p.token}`));

const profileToken = profiles[0].token;
```

The `ptz` proxy controls camera movement.

```js
const presets = await ptz.getPresets(profileToken); // READ_MEDIA
console.log(presets[0]);

// Get live PTZ status
const status = await ptz.getStatus(profileToken);
console.log(status.position.panTilt);
```

Always release the handle when finished:

```js
onvif.disconnect(handle);
```

## Build

```sh
# One-time
dart pub get

# Produce build/node/easy_onvif.js (staged into npm/easy-onvif-node/dist/)
./tool/build_node.sh

# Produce build/web/easy_onvif.js  (staged into npm/easy-onvif-web/dist/)
./tool/build_web.sh
```

Outputs are staged into `npm/easy-onvif-node/dist/` and
`npm/easy-onvif-web/dist/` ready for `npm publish`.

## Smoke test (Node)

```sh
node tool/smoke_test_node.mjs
```

## Supported Onvif Operations

The following tables list every operation that is currently wired up in the
JS surface. The **Onvif Operation** column matches the spec, the **JS Method**
column is the exact property name on the service proxy, and the **Return
Type** column describes the JSON-serialisable shape returned from the
underlying Dart call.

### Device Management

  * [Specification PDF](https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf)
  * [wsdl](https://www.onvif.org/onvif/ver10/device/wsdl/devicemgmt.wsdl)

| Onvif Operation         | JS Method                | JS Return Type                        |
| ----------------------- | ------------------------ | ------------------------------------- |
| GetCapabilities         | `getCapabilities`        | `Promise<Record<string, unknown>>`    |
| GetDeviceInformation    | `getDeviceInformation`   | `Promise<DeviceInformation>`          |
| GetDiscoveryMode        | `getDiscoveryMode`       | `Promise<string>`                     |
| GetDNS                  | `getDNS`                 | `Promise<Record<string, unknown>>`    |
| GetHostname             | `getHostname`            | `Promise<Record<string, unknown>>`    |
| GetNTP                  | `getNTP`                 | `Promise<Record<string, unknown>>`    |
| GetServiceCapabilities  | `getServiceCapabilities` | `Promise<Record<string, unknown>>`    |
| GetServices             | `getServices`            | `Promise<Record<string, unknown>[]>`  |
| GetSystemDateAndTime    | `getSystemDateAndTime`   | `Promise<SystemDateAndTime>`          |
| GetUsers                | `getUsers`               | `Promise<User[]>`                     |
| SystemReboot            | `systemReboot`           | `Promise<string>`                     |

### Media

  * [Media ver10 PDF](https://www.onvif.org/specs/srv/media/ONVIF-Media-Service-Spec.pdf) / [wsdl](https://www.onvif.org/ver10/media/wsdl/media.wsdl)
  * [Media ver20 PDF](https://www.onvif.org/specs/srv/media/ONVIF-Media2-Service-Spec.pdf) / [wsdl](https://www.onvif.org/ver20/media/wsdl/media.wsdl)

The Media proxy exposes both Media1 and Media2 operations. Methods suffixed
with `2` delegate to the Media2 service when the device advertises it.

| Onvif Operation            | JS Method                   | JS Return Type                        |
| -------------------------- | --------------------------- | ------------------------------------- |
| GetServiceCapabilities     | `getServiceCapabilities`    | `Promise<Record<string, unknown>>`    |
| GetProfiles                | `getProfiles`               | `Promise<Profile[]>`                  |
| GetProfile                 | `getProfile`                | `Promise<Profile>`                    |
| GetStreamUri (Media1)      | `getStreamUri`              | `Promise<string>`                     |
| GetStreamUri (Media2)      | `getStreamUri2`             | `Promise<string>`                     |
| GetSnapshotUri (Media1)    | `getSnapshotUri`            | `Promise<string>`                     |
| GetSnapshotUri (Media2)    | `getSnapshotUri2`           | `Promise<string>`                     |
| GetMetadataConfiguration   | `getMetadataConfiguration`  | `Promise<Record<string, unknown>>`    |
| GetMetadataConfigurations  | `getMetadataConfigurations` | `Promise<Record<string, unknown>[]>`  |

### PTZ

  * [Specification PDF](https://www.onvif.org/specs/srv/ptz/ONVIF-PTZ-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver20/ptz/wsdl/ptz.wsdl)

| Onvif Operation          | JS Method                  | JS Return Type                        |
| ------------------------ | -------------------------- | ------------------------------------- |
| GetServiceCapabilities   | `getServiceCapabilities`   | `Promise<Record<string, unknown>>`    |
| GetConfigurations        | `getConfigurations`        | `Promise<PtzConfiguration[]>`         |
| GetConfiguration         | `getConfiguration`         | `Promise<PtzConfiguration>`           |
| GetConfigurationOptions  | `getConfigurationOptions`  | `Promise<PtzConfigurationOptions>`    |
| GetPresets               | `getPresets`               | `Promise<Preset[]>`                   |
| GetStatus                | `getStatus`                | `Promise<PtzStatus>`                  |
| SetHomePosition          | `setHomePosition`          | `Promise<boolean>`                    |
| Stop                     | `stop`                     | `Promise<boolean>`                    |

### Imaging

  * [Specification PDF](https://www.onvif.org/specs/srv/img/ONVIF-Imaging-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver20/imaging/wsdl/imaging.wsdl)

| Onvif Operation          | JS Method                 | JS Return Type                        |
| ------------------------ | ------------------------- | ------------------------------------- |
| GetServiceCapabilities   | `getServiceCapabilities`  | `Promise<Record<string, unknown>>`    |
| GetImagingSettings       | `getImagingSettings`      | `Promise<Record<string, unknown>>`    |
| SetImagingSettings       | `setImagingSettings`      | `Promise<boolean>`                    |
| GetOptions               | `getOptions`              | `Promise<Record<string, unknown>>`    |
| GetStatus                | `getStatus`               | `Promise<ImagingStatus>`              |
| Move                     | `move`                    | `Promise<boolean>`                    |
| Stop                     | `stop`                    | `Promise<boolean>`                    |

### Recordings

  * [Specification PDF](https://www.onvif.org/specs/srv/rec/ONVIF-RecordingControl-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver10/recording.wsdl)

| Onvif Operation                 | JS Method                        | JS Return Type                        |
| ------------------------------- | -------------------------------- | ------------------------------------- |
| GetServiceCapabilities          | `getServiceCapabilities`         | `Promise<Record<string, unknown>>`    |
| GetRecordings                   | `getRecordings`                  | `Promise<Record<string, unknown>[]>`  |
| GetRecordingConfiguration       | `getRecordingConfiguration`      | `Promise<Record<string, unknown>>`    |
| SetRecordingConfiguration       | `setRecordingConfiguration`      | `Promise<boolean>`                    |
| CreateRecording                 | `createRecording`                | `Promise<string>`                     |
| DeleteRecording                 | `deleteRecording`                | `Promise<boolean>`                    |
| GetRecordingJobs                | `getRecordingJobs`               | `Promise<Record<string, unknown>[]>`  |
| GetRecordingJobConfiguration    | `getRecordingJobConfiguration`   | `Promise<Record<string, unknown>>`    |
| SetRecordingJobConfiguration    | `setRecordingJobConfiguration`   | `Promise<boolean>`                    |
| CreateRecordingJob              | `createRecordingJob`             | `Promise<Record<string, unknown>>`    |
| DeleteRecordingJob              | `deleteRecordingJob`             | `Promise<boolean>`                    |

### Replay

  * [Specification PDF](https://www.onvif.org/specs/srv/replay/ONVIF-ReplayControl-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver10/replay.wsdl)

| Onvif Operation             | JS Method                  | JS Return Type                        |
| --------------------------- | -------------------------- | ------------------------------------- |
| GetServiceCapabilities      | `getServiceCapabilities`   | `Promise<Record<string, unknown>>`    |
| GetReplayUri                | `getReplayUri`             | `Promise<string>`                     |
| GetReplayConfiguration      | `getReplayConfiguration`   | `Promise<Record<string, unknown>>`    |
| SetReplayConfiguration      | `setReplayConfiguration`   | `Promise<boolean>`                    |

### Search

  * [Specification PDF](https://www.onvif.org/specs/srv/rsrch/ONVIF-RecordingSearch-Service-Spec.pdf)
  * [wsdl](https://www.onvif.org/ver10/search.wsdl)

| Onvif Operation             | JS Method                  | JS Return Type                        |
| --------------------------- | -------------------------- | ------------------------------------- |
| GetSearchCapabilities       | `getSearchCapabilities`    | `Promise<Record<string, unknown>>`    |
| GetRecordingSummary         | `getRecordingSummary`      | `Promise<Record<string, unknown>>`    |
| FindRecordings              | `findRecordings`           | `Promise<string>`                     |
| FindEvents                  | `findEvents`               | `Promise<string>`                     |

## Onvif Probe

The `easy-onvif-node` artifact ships a top-level `probe()` method that
executes WS-Discovery over UDP multicast (239.255.255.250:3702) using
`node:dgram` and returns the raw probe matches.

```js
import { loadEasyOnvif } from 'easy-onvif-node';

const onvif   = await loadEasyOnvif();
const matches = await onvif.probe(3); // seconds

for (const m of matches) {
  console.log(m.endpointReference.address, m.xAddrs);
}
```

WS-Discovery is **not** available in the browser build — calling `probe()` on
`easy-onvif-web` throws `UnsupportedError`.

## Known limitations

- **Browser build**: all HTTP is performed via `fetch`, so ONVIF endpoints
  must be reachable without a CORS preflight rejection. A reverse proxy is
  typically required for production use.
- **Node 25+ `dgram`**: newer Node builds have stricter multicast interface
  binding. If `probe()` returns no matches, verify that the network
  interface has an IPv4 address bound.
- **Handle lifecycle**: every `connect()` allocates a Dart-side handle; call
  `disconnect(handle)` when you are finished to release the SOAP transport.

## Features and bugs

Please file feature requests and bugs with
[the issue tracker](https://github.com/faithoflifedev/easy_onvif/issues).

## Contributing

Any help from the open-source community is always welcome and needed. See
the contributor list and workflow in the
[parent project README](https://github.com/faithoflifedev/easy_onvif/blob/main/README.md#contributing).
