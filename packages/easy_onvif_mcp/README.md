# easy_onvif_mcp

An [MCP](https://modelcontextprotocol.io) (Model Context Protocol) server that
exposes ONVIF IP cameras and NVRs as tools, built on
[`easy_onvif`](https://pub.dev/packages/easy_onvif).

Point a model at a camera: list profiles, resolve RTSP and snapshot URIs, drive
PTZ, read device information, and discover devices over WS-Discovery — without
writing a single SOAP request by hand.

[![Pub Version](https://img.shields.io/pub/v/easy_onvif_mcp.svg?logo=dart)](https://pub.dev/packages/easy_onvif_mcp)

## Installation

Homebrew (native binary, macOS and Linux):

```sh
brew tap cdavis-code/easy-onvif
brew install easy-onvif-mcp
```

Or install the Dart package and run the compiled entry point:

```sh
dart pub global activate easy_onvif_mcp
```

Both install the same server and speak MCP over stdio. The command they place
on your PATH is `easy-onvif-mcp` (Homebrew) or `easy_onvif_mcp` (Dart global
activation). `--help` and `--version` print and exit without starting the
server. The Homebrew tap serves binaries from the project's GitHub Releases, so
it becomes available with the first native release.

## How it is built

The tools are declared once, as `@Tool`-annotated methods on
[`EasyOnvifMcpServer`](lib/src/easy_onvif_mcp_server.dart).
[`easy_api_generator`](https://pub.dev/packages/easy_api_generator) turns those
annotations into the stdio dispatcher behind `bin/easy_onvif_mcp_server.dart`,
so there is no hand-maintained schema to keep in step:

```sh
cd packages/easy_onvif_mcp
dart run build_runner build   # regenerates src/easy_onvif_mcp_server.mcp.dart
```

`bin/easy_onvif_mcp_server.dart` is the file both installation methods above
run — Homebrew installs it as the `easy-onvif-mcp` binary and `dart pub global
activate` exposes it as `easy_onvif_mcp`.

## Credentials

Resolved lazily on the first tool call, environment winning over the config
file:

1. `ONVIF_HOST`, `ONVIF_USERNAME`, `ONVIF_PASSWORD` — all three, or none.
2. `$HOME/.onvif/credentials.json` — the encrypted bundle `easy_onvif_cli`
   writes (`onvif credentials init`), or a plaintext file from an older
   version. Override the path with `ONVIF_CONFIG_FILE`; choose a device with
   `ONVIF_DEVICE` (otherwise the bundle's default).
3. Or call the `onvif_connect` tool with `host` and `username`; the password
   still comes from the sources above.

The bundle is sealed with AES-256-GCM. Its key is read from `ONVIF_KEY_FILE` /
`ONVIF_KEY`, the OS keychain, or a passphrase prompt — the same providers the
CLI uses, so `onvif credentials key init` provisions this server too. A file
that exists but cannot be opened (missing key, wrong key, tampering) fails with
the precise remedy instead of silently ignoring the file.


`ONVIF_HOST` may carry a port (`192.168.1.10:8080`) or a scheme. Nothing is read
until a tool needs it, so the server always starts.

## Client configuration

Point the MCP host at the installed command:

```json
{
  "mcpServers": {
    "onvif": {
      "command": "easy-onvif-mcp",
      "env": {
        "ONVIF_HOST": "192.168.1.10",
        "ONVIF_USERNAME": "admin",
        "ONVIF_PASSWORD": "secret"
      }
    }
  }
}
```

If you installed with `dart pub global activate`, use `"command":
"easy_onvif_mcp"` instead (or `"command": "dart", "args": ["pub", "global",
"run", "easy_onvif_mcp"]`).

## Tools

52 tools, all prefixed `onvif_`. Media and PTZ tools take a `profile_token`;
get one from `onvif_get_profiles`. The handshake snippet under
[Development](#development) prints the live list with each tool's schema.

**Connection** — `onvif_connect`, `onvif_disconnect`, `onvif_is_connected`,
`onvif_status`, `onvif_probe`

**Device management (read-only)** — `onvif_get_device_information`,
`onvif_get_services`, `onvif_get_capabilities`,
`onvif_get_system_date_and_time`, `onvif_get_hostname`, `onvif_get_dns`,
`onvif_get_ntp`, `onvif_get_dynamic_dns`, `onvif_get_network_protocols`,
`onvif_get_users`, `onvif_get_relay_outputs`,
`onvif_get_storage_configurations`, `onvif_get_discovery_mode`,
`onvif_get_endpoint_reference`

**Media** — `onvif_get_profiles`, `onvif_get_profile`, `onvif_get_stream_uri`,
`onvif_get_snapshot_uri`, `onvif_get_video_sources`,
`onvif_get_audio_sources`, `onvif_get_media_service_capabilities`

**PTZ** — `onvif_ptz_get_status`, `onvif_ptz_get_presets`,
`onvif_ptz_get_configurations`, `onvif_ptz_goto_preset`,
`onvif_ptz_set_preset`, `onvif_ptz_remove_preset`,
`onvif_ptz_absolute_move`, `onvif_ptz_relative_move`,
`onvif_ptz_continuous_move`, `onvif_ptz_stop`, `onvif_ptz_move`,
`onvif_ptz_move_up`, `onvif_ptz_move_down`, `onvif_ptz_move_left`,
`onvif_ptz_move_right`, `onvif_ptz_zoom`,
`onvif_ptz_get_service_capabilities`

**Imaging (read-only)** — `onvif_imaging_get_status`,
`onvif_imaging_get_presets`, `onvif_imaging_get_current_preset`

**Recordings / replay / search** — `onvif_get_recordings`,
`onvif_get_recording_jobs`, `onvif_get_replay_uri`,
`onvif_get_recording_summary`, `onvif_find_recordings`,
`onvif_get_recording_search_results`

### What is deliberately not exposed

Device-mutating operations — `system_reboot`, user creation/deletion, hostname,
DNS, NTP, network protocol and IP-filter writes — are **not** tools here. A
stdio server holding live camera credentials should not hand a model a reboot
button by default. Everything exposed is either a read or a camera movement.

Two reads the ONVIF spec defines have no counterpart in the `easy_onvif` API and
so are absent: `GetScopes`, and imaging options/settings beyond
`ImagingStatus20` (`onvif_imaging_get_status` is the closest available).
Add them once the core exposes those requests — one `@Tool` method each.

### Credentials are never echoed back

`dart_mcp`'s automatic argument validation quotes the rejected value in its
failure message — ``Value `12345` is not of type `String` at
path #root["password"]`` — and numeric default passwords are common on ONVIF
cameras. The password is therefore never a tool argument at all: `onvif_connect`
takes a host and a username, and the password comes only from the environment or
the credentials file. Errors name the offending field only.

### One device at a time

Tool calls are serialized. `easy_onvif`'s SOAP layer keeps its clock offset and
XML builder in static state (`Transport.timeDelta`, `Transport.builder`), so two
in-flight requests would corrupt each other's WS-Security timestamps and XML
fragments. Serializing keeps correctness at the cost of throughput, and means
this server talks to one device per process — connect to a second camera by
running a second server.

## Diagnostics

stdout is the JSON-RPC channel, so every log line, including SOAP failures and
stack traces, goes to stderr. Tool failures come back as a normal MCP result
with `isError: true` and a one-line message.

## Development

```sh
dart test
dart run build_runner build   # after touching any @Tool method
```

To poke the server by hand:

```sh
{ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'; sleep 2; } \
  | dart run bin/easy_onvif_mcp_server.dart
```

The `sleep` matters: closing stdin ends the session, and a piped heredoc
closes before the async reply is written.
