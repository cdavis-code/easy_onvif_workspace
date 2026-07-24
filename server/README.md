# easy_onvif_server

A Flutter application that turns a device (desktop or mobile) into an
ONVIF-compatible IP camera. It implements the same SOAP API surface that the
[`easy_onvif`](../packages/easy_onvif) client library consumes, so you can
develop and test ONVIF integrations without physical camera hardware.

## Features

- **ONVIF SOAP services** — Device Management, Media1/Media2, and PTZ, with
  WS-Security `UsernameToken` authentication.
- **Live RTSP streaming** — an embedded RTSP server serves H.264 encoded by
  `ffmpeg` (RTP over TCP interleaved).
- **HTTP snapshots** — JPEG frames from the device camera.
- **WS-Discovery** — the device announces itself and answers `Probe` messages,
  so discovery-based clients can find it on the local network.
- **Hardware integration** — camera and geolocation via the `camera` and
  `geolocator` Flutter plugins, with graceful fallback when hardware is
  unavailable.

## Requirements

- Flutter SDK (see the workspace root for the pinned Dart/Flutter versions).
- `ffmpeg` available on `PATH` for RTSP streaming on desktop
  (`brew install ffmpeg` on macOS).

## Running the server

```sh
cd server
flutter pub get
flutter run -d macos        # or: -d ios, -d android
```

When it starts, the app displays the server's network address, the ONVIF
device-service URL, the RTSP stream URL, and the credentials it accepts.

## Configuration

Defaults are defined by `ServerConfig` in [`lib/src/config.dart`](lib/src/config.dart):

| Setting             | Default                |
| ------------------- | ---------------------- |
| HTTP (SOAP) port    | `8080`                 |
| RTSP port           | `8554`                 |
| WS-Discovery port   | `3702`                 |
| Username            | `admin`                |
| Password            | `admin`                |
| Manufacturer        | `easy_onvif`           |
| Model               | `Dart ONVIF Server`    |
| Firmware version    | `0.1.0`                |

Advertised endpoints (replace `<host>` with the server's IP):

| Endpoint        | URL                                            |
| --------------- | ---------------------------------------------- |
| Device service  | `http://<host>:8080/onvif/device_service`      |
| RTSP stream     | `rtsp://<host>:8554/onvif/Profile_1`           |
| JPEG snapshot   | `http://<host>:8080/onvif/snapshot/Profile_1`  |

## Using the server with the example project

The [`packages/easy_onvif/example`](../packages/easy_onvif/example) Flutter app
is an `easy_onvif` **client**. Pointing it at this server lets you see the
client and server working together end to end — no real camera required.

### 1. Start the server

Run the server as described above and note two things from its UI:

- the server's **IP address** (e.g. `192.168.1.50`), and
- the **credentials** it accepts (default `admin` / `admin`).

### 2. Configure the example app

The example reads its connection settings from `assets/config.yaml`. Create it
from the provided sample:

```sh
cd packages/easy_onvif/example
cp assets/config.sample.yaml assets/config.yaml
```

Edit `assets/config.yaml` to point at the server:

```yaml
host: "192.168.1.50:8080"
username: "admin"
password: "admin"
```

> **Important — include the `:8080` port.** The `easy_onvif` client derives the
> service URL from the host's origin, and this server listens on port `8080`
> (not `80`). Use `localhost:8080` when the example runs on the same machine as
> the server, or the server's LAN IP (shown in the server app) when the two run
> on separate devices on the same network.

### 3. Run the example

```sh
cd packages/easy_onvif/example
flutter pub get
flutter run
```

On launch the example connects to the server and displays:

- **Device Manufacturer:** `easy_onvif`
- **Model:** `Dart ONVIF Server`
- **Firmware Version:** `0.1.0`
- a live **JPEG snapshot** from the server's camera (tap **Get** to refresh).

### Viewing the live RTSP stream

The example shows device information and snapshots over HTTP. To watch the live
RTSP video, open the stream URL in a player such as VLC:

```sh
vlc rtsp://192.168.1.50:8554/onvif/Profile_1
```

### Notes

- Both apps must be reachable on the same network; the example connects to the
  IP you put in `config.yaml`.
- The snapshot reflects the server's camera. If the server has no camera
  available, the snapshot endpoint returns `404` and the example shows an error
  icon — device information and profiles still work.
- The example depends on `easy_onvif` via a path dependency, so it exercises
  the exact client code that this server is built to mirror.

## Project layout

```
lib/
  main.dart                     # Flutter app shell + status UI
  src/
    config.dart                 # ServerConfig defaults
    onvif_device.dart           # Assembles and runs the whole device
    server/                     # HTTP server + SOAP dispatcher
    soap/                       # Envelope builder, request parser, auth
    services/                   # DeviceManagement, Media1/2, PTZ
    streaming/                  # ffmpeg H.264 source, RTP packetizer, RTSP server
    discovery/                  # WS-Discovery responder
    hardware/                   # HardwareAdapter interface + Flutter (camera/geo) impl
```

## Testing

Integration tests drive the **real** `easy_onvif` client against the server
(connect + device info + auth, media profiles / stream / snapshot, PTZ moves
and presets, live RTSP recording, and WS-Discovery):

```sh
cd server
flutter test
```
