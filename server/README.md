# easy_onvif_server

A Flutter application that turns a device (desktop or mobile) into an
ONVIF-compatible IP camera. It implements the same SOAP API surface that the
[`easy_onvif`](../packages/easy_onvif) client library consumes, so you can
develop and test ONVIF integrations without physical camera hardware.

## Features

- **ONVIF SOAP services** — Device Management, Media1/Media2, PTZ, Imaging,
  Recording, Search, and Replay, with WS-Security `UsernameToken`
  authentication.
- **Live RTSP streaming** — an embedded RTSP server serves H.264 encoded by
  `ffmpeg` (RTP over TCP interleaved).
- **Real recording pipeline** — recording jobs capture the live H.264 stream
  to disk as Annex-B segments; Search queries the on-disk indexes and Replay
  serves the recorded footage back over RTSP.
- **HTTP snapshots** — JPEG frames from the device camera.
- **WS-Discovery** — the device announces itself and answers `Probe` messages,
  so discovery-based clients can find it on the local network.
- **Hardware integration** — camera and geolocation via the `camera` and
  `geolocator` Flutter plugins, with graceful fallback when hardware is
  unavailable.

### Services

| Service           | Namespace | Highlights                                            |
| ----------------- | --------- | ----------------------------------------------------- |
| Device Management | `tds`     | Device info, users, capabilities, system log, storage |
| Media 1           | `trt`     | Profiles, stream/snapshot URIs, metadata configs      |
| Media 2           | `tr2`     | Profiles, encoder/source options, multicast stubs     |
| PTZ               | `tptz`    | Continuous/absolute/relative moves, presets, home     |
| Imaging           | `timg`    | Simulated presets (settings-seeded), focus status     |
| Recording         | `trc`     | Real capture jobs writing `.h264` segments to disk    |
| Search            | `tse`     | Finds recordings and time ranges from disk indexes    |
| Replay            | `trp`     | RTSP replay URIs serving recorded segments            |

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

### Settings file

At startup the app loads YAML settings, searching in order:

1. `~/.easy_onvif_server/settings.yaml` (runtime override)
2. the bundled [`assets/settings.yaml`](assets/settings.yaml) (all keys
   commented — pure defaults)

Every key is optional; missing keys fall back to the defaults above. Schema:

```yaml
device:
  manufacturer: easy_onvif
  model: Dart ONVIF Server
  firmware: 0.1.0
  serial: EASY-ONVIF-SERVER-0001
  hardwareId: "1"
  hostname: easy-onvif-server
network:
  httpPort: 8080
  rtspPort: 8554
auth:
  username: admin
  password: admin
services:          # enable/disable optional services
  recording: true
  replay: true
  search: true
  imaging: true
recording:
  directory: /path/to/recordings   # default: system temp
  segmentSeconds: 10               # segment rotation length
  maxRetentionMinutes: 60          # default: unlimited
imaging:
  presets:            # define at least two (the client parses a preset list)
    - token: ImagingPreset_1
      name: Standard
      type: Auto
    - token: ImagingPreset_2
      name: Low Light
      type: LowLight
geolocation:       # GetGeoLocation fallback when no platform fix
  lat: 43.65
  lon: -79.38
  elevation: 76.0
```

### Recording storage

Each recording lives in its own directory under the recordings root:

```
<recording directory>/
  OnvifRecordingToken_1/
    index.json          # metadata: source, frame rate, segment time ranges
    seg_00001.h264      # keyframe-aligned Annex-B segments (SPS/PPS prefixed)
    seg_00002.h264
```

Recordings survive restarts — the store reloads `index.json` files at startup.
When `maxRetentionMinutes` is set, segments older than the window are pruned
on rotation.

Advertised endpoints (replace `<host>` with the server's IP):

| Endpoint        | URL                                                 |
| --------------- | --------------------------------------------------- |
| Device service  | `http://<host>:8080/onvif/device_service`           |
| RTSP stream     | `rtsp://<host>:8554/onvif/Profile_1`                |
| RTSP replay     | `rtsp://<host>:8554/onvif/replay/<recordingToken>`  |
| JPEG snapshot   | `http://<host>:8080/onvif/snapshot/Profile_1`       |

The replay endpoint serves a recording's segments from disk; `GetReplayUri`
returns the URL for a given recording token, and `PLAY` accepts a
`Range: clock=` header to seek within the recording.

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
    settings.dart               # YAML settings loader (ServerSettings)
    onvif_device.dart           # Assembles and runs the whole device
    server/                     # HTTP server + SOAP dispatcher
    soap/                       # Envelope builder, request parser, auth
    services/                   # DeviceManagement, Media1/2, PTZ, Imaging,
                                #   Recording, Search, Replay
    recording/                  # Segment recorder, on-disk store + JSON index
    streaming/                  # ffmpeg H.264 source, file replay source,
                                #   RTP packetizer, RTSP server
    discovery/                  # WS-Discovery responder
    hardware/                   # HardwareAdapter interface + Flutter (camera/geo) impl
assets/
  settings.yaml                 # Bundled settings template (all keys commented)
```

## Testing

Integration tests drive the **real** `easy_onvif` client against the server
(connect + device info + auth, media profiles / stream / snapshot, PTZ moves
and presets, imaging presets, live RTSP recording, recording jobs capturing to
disk, replay over RTSP, search over recorded ranges, and WS-Discovery):

```sh
cd server
flutter test
```
