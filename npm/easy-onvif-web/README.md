# easy-onvif-web

Browser [ONVIF](https://www.onvif.org/) client, compiled from the Dart
[`easy_onvif`](https://pub.dev/packages/easy_onvif) package with `dart2wasm`.

> For Node.js (including WS-Discovery) see
> [`easy-onvif-node`](https://www.npmjs.com/package/easy-onvif-node).

## What works in a browser?

| Feature | Status | Notes |
| --- | --- | --- |
| SOAP `connect` / `getDeviceInformation` | ✅ | Through `fetch` + digest auth. |
| Media `getProfiles` / `getStreamUri` / `getSnapshotUri` | ✅ | Same SOAP stack. |
| PTZ `absoluteMove` | ✅ | — |
| WS-Discovery (`probe`) | ❌ | Rejects with `UnsupportedError`. Browsers cannot open UDP sockets. |

### CORS

ONVIF devices do not emit `Access-Control-Allow-Origin` headers. The browser
**will** block cross-origin SOAP calls unless you place a reverse proxy in
front of the camera that terminates digest auth and adds CORS headers. Common
choices: nginx, Caddy, a lightweight Node.js proxy, or a home-assistant
style gateway.

### Mixed content

A page served over HTTPS cannot talk to a camera on `http://`. Either expose
the proxy over HTTPS, or serve your UI over HTTP (e.g. on a LAN).

## Requirements

Browsers with [WasmGC](https://webassembly.org/features/) enabled:

- Chromium **119+**
- Firefox **120+**
- Safari **18.2+**

## Install

```sh
npm install easy-onvif-web
```

## Quick start (Vite / webpack / Parcel)

```js
import { loadEasyOnvif } from 'easy-onvif-web';

const onvif = await loadEasyOnvif();

const handle = await onvif.connect({
  host: 'camera.example.local',
  username: 'admin',
  password: 'secret',
});

const info = await onvif.getDeviceInformation(handle);
console.log(info);

const [profile] = await onvif.getProfiles(handle);
const snapshotUri = await onvif.getSnapshotUri(handle, profile.token);

onvif.disconnect(handle);
```

The loader uses `new URL('./dist/easy_onvif.wasm', import.meta.url)`, which
modern bundlers recognize as an asset reference and will copy into the build
output automatically.

## API

See [`index.d.ts`](./index.d.ts).

## License

MIT
