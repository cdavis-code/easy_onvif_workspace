# easy_onvif Examples

This directory contains an example application demonstrating how to use the `easy_onvif` package with Flutter.

## Examples

### Flutter example app

A Flutter application ([`lib/main.dart`](lib/main.dart)) that demonstrates:

- Connecting to an ONVIF device using credentials stored in `assets/config.yaml`
- Reading device information (manufacturer, model, firmware version)
- Listing media profiles
- Viewing the device as a still **JPEG snapshot** or a **live video** stream
  (toggle in the UI):
  - **Native** (mobile/desktop): live RTSP playback via `media_kit`
  - **Web** (`flutter run -d chrome`): live WebRTC playback via
    [`lib/webrtc_player.dart`](lib/webrtc_player.dart), since browsers can't
    play RTSP
- Discovering ONVIF devices on the local network via WS-Discovery ([`lib/device_page.dart`](lib/device_page.dart))

## Getting Started

1. Ensure your ONVIF-compatible device is connected to the same network.
2. Create your connection config from the sample:
   ```bash
   cp assets/config.sample.yaml assets/config.yaml
   ```
3. Edit `assets/config.yaml` with your device's address and credentials
   (include a port if the device uses one):
   ```yaml
   host: "192.168.1.123"        # e.g. "192.168.1.177:8000"
   username: "admin"
   password: "admin"
   ```
4. Run the example:
   ```bash
   flutter pub get
   flutter run
   ```

> **No ONVIF device handy?** Run the workspace's software ONVIF camera,
> [`easy_onvif_server`](../../../server/README.md), and point `config.yaml` at
> it instead — for example `host: "localhost:8080"`, `username: "admin"`,
> `password: "admin"`.

For more detailed examples and CLI usage, see:

- [easy_onvif_cli examples](../../easy_onvif_cli/example)
- [Full documentation](../README.md)
