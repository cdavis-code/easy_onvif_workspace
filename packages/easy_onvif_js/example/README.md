# easy_onvif_js — Example programs

This directory contains example Node.js programs that exercise the
[`easy-onvif-node`](../../../npm/easy-onvif-node) npm package compiled from
`@packages/easy_onvif_js`.

## Prerequisites

- **Node.js ≥ 20** (WasmGC is on by default).
- The `easy-onvif-node` npm artifacts must be **built** before running the
  examples. From the workspace root:

  ```sh
  # Build both npm artifacts at once
  melos run build:npm

  # Or just the Node side
  melos run build:npm:node
  ```

  This stages the compiled `.wasm` + `.mjs` loader into
  `../../../npm/easy-onvif-node/dist/`.

## Quick reference

| Script | Command | Description |
| --- | --- | --- |
| `discover_and_info.mjs` | `node discover_and_info.mjs` | Probes the network for ONVIF cameras, then connects to one and queries device info, profiles, and stream URIs. |
| `ptz_demo.mjs` | `CAMERA_HOST=… CAMERA_PASSWORD=… node ptz_demo.mjs` | Connects to a known camera and runs a series of PTZ absolute moves. |

## Test server (happytime-rtsp-server)

The examples work with the [happytime-rtsp-server](https://github.com/ant-media/utilities/blob/master/happytime-rtsp-server/) ONVIF simulator.
Its defaults are hard-coded into the usage hints:

| Setting | Default |
| --- | --- |
| Host | `localhost:6554` |
| Username | `admin` |
| Password | `123456` |
| Auth required | No (`need_auth=0` in config.xml) |

> **PTZ**: The test server does **not** support PTZ. The `ptz_demo.mjs` script
> detects this and exits gracefully with a clear message.

## Example 1 — Discover and interrogate

```sh
cd packages/easy_onvif_js/example
node discover_and_info.mjs
```

The script:

1. **WS-Discovery** — sends a multicast probe and listens for ONVIF camera
   responses for 3 seconds. Every responding device is printed to the console.
2. **Connect** — picks the first discovered camera, asks for the password if
   not provided, and opens a SOAP session.
3. **Device Information** — calls `getDeviceInformation` and prints the
   manufacturer, model, firmware, etc.
4. **Profiles** — lists available media profiles.
5. **Stream URIs** — fetches the RTSP stream URI and HTTP snapshot URI for
   the first profile.
6. **Cleanup** — disconnects.

If no ONVIF cameras are reachable on your network you can still test the
connection path by providing credentials through environment variables:

```sh
CAMERA_HOST=192.168.1.64:8000 \
CAMERA_PASSWORD=secret \
  node discover_and_info.mjs
```

To skip the network discovery step entirely (e.g. for a local test server):

```sh
CAMERA_HOST=localhost:6554 \
CAMERA_PASSWORD=123456 \
  node discover_and_info.mjs
```

## Example 2 — PTZ demo

> ⚠ **The happytime-rtsp-server test server does NOT support PTZ.** Use a
> real ONVIF PTZ camera to run this example.

```sh
CAMERA_HOST=192.168.1.64:8000 \
CAMERA_PASSWORD=secret \
  node ptz_demo.mjs
```

The script first probes PTZ availability with a single `absoluteMove` call.
If the device responds with an error (expected for the test server), it
prints a clear message and exits cleanly. Otherwise it walks through a
full move sequence:

| Action | Pan | Tilt | Zoom |
| --- | --- | --- | --- |
| Centre (home) | 0.0 | 0.0 | 0.0 |
| Pan right | 0.5 | 0.0 | 0.0 |
| Pan left | 0.0 | 0.0 | 0.0 |
| Tilt down | 0.0 | 0.5 | 0.0 |
| Tilt up | 0.0 | 0.0 | 0.0 |
| Zoom in | 0.0 | 0.0 | 0.5 |
| Zoom out | 0.0 | 0.0 | 0.0 |

Coordinates are normalised `0.0 – 1.0` where `0.0` means home/centre for
each axis.

You can optionally pin a profile:

```sh
PROFILE_TOKEN=profile_token_1 \
CAMERA_HOST=192.168.1.64:8000 \
CAMERA_PASSWORD=secret \
  node ptz_demo.mjs
```

## No npm install needed

Both examples import the npm package via a **relative path**:

```js
import { loadEasyOnvif } from '../../../npm/easy-onvif-node/index.mjs';
```

This keeps the example self-contained inside the monorepo. If you want to
test the published package instead, replace the import with the package name:

```js
import { loadEasyOnvif } from 'easy-onvif-node';
```

and then `npm install easy-onvif-node`.
