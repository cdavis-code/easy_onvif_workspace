# easy_onvif_mcp

An [MCP](https://modelcontextprotocol.io) (Model Context Protocol) server that
exposes ONVIF IP cameras and NVRs as tools, built on
[`easy_onvif`](https://pub.dev/packages/easy_onvif).

Point a model at a camera: list profiles, resolve RTSP and snapshot URIs, drive
PTZ, read device information, and discover devices over WS-Discovery — without
writing a single SOAP request by hand.

[![Pub Version](https://img.shields.io/pub/v/easy_onvif_mcp.svg?logo=dart)](https://pub.dev/packages/easy_onvif_mcp)

## How it is built

The tools are declared once, as `@Tool`-annotated methods on
[`EasyOnvifMcpServer`](lib/src/easy_onvif_mcp_server.dart).
[`easy_api_generator`](https://pub.dev/packages/easy_api_generator) turns those
annotations into the stdio dispatcher, so there is no hand-maintained schema and
no separate registry to keep in step:

```sh
cd packages/easy_onvif_mcp
dart run build_runner build   # regenerates src/easy_onvif_mcp_server.mcp.dart
```

| Artifact | Entry point | How you run it |
| --- | --- | --- |
| pub.dev / Dart VM | `bin/easy_onvif_mcp_server.dart` (generated dispatcher) | `dart pub global activate easy_onvif_mcp` |
| npm / Node.js | `lib/src/js/entry.dart` → `dist/` (compiled with `dart compile js`) | `npx -y easy-onvif-mcp` |

The generated dispatcher imports `dart:io`, which cannot be compiled to JS, so
the npm artifact keeps a small registry of tool names and JSON schemas in
`lib/src/js/tools.dart` and calls the same annotated methods.
`test/tool_defs_test.dart` fails if the two lists ever diverge.

## Credentials

Resolved lazily on the first tool call, environment winning over the config
file:

1. `ONVIF_HOST`, `ONVIF_USERNAME`, `ONVIF_PASSWORD`
2. `$HOME/.onvif/credentials.json` — the same file `easy_onvif_cli` reads, so
   `onvif authorize` sets up this server too. Override the path with
   `ONVIF_CONFIG_FILE`.
3. Or call the `onvif_connect` tool explicitly. On the Dart VM it takes `host`
   and `username`, and reads the password from the sources above; the npm build
   accepts `host`, `username` and `password` directly, because an `npx` process
   has no reliable home directory for the credentials file.

`ONVIF_HOST` may carry a port (`192.168.1.10:8080`) or a scheme. Nothing is read
until a tool needs it, so the server always starts.

## Client configuration

```json
{
  "mcpServers": {
    "onvif": {
      "command": "npx",
      "args": ["-y", "easy-onvif-mcp"],
      "env": {
        "ONVIF_HOST": "192.168.1.10",
        "ONVIF_USERNAME": "admin",
        "ONVIF_PASSWORD": "secret"
      }
    }
  }
}
```

With the Dart VM binary, use `"command": "dart", "args": ["run", "easy_onvif_mcp:easy_onvif_mcp_server"]`.

## Tools

52 tools, all prefixed `onvif_`. Media and PTZ tools take a `profile_token`;
get one from `onvif_get_profiles`. Run `dart run example/serve_stdio.dart
--list-tools` to print the live list with each tool's required arguments.

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
Add them once the core exposes those requests — one `ToolDef` entry each.

### Credentials are never echoed back

`dart_mcp`'s automatic argument validation quotes the rejected value in its
failure message — ``Value `12345` is not of type `String` at
path #root["password"]`` — and numeric default passwords are common on ONVIF
cameras. The password is therefore never a schema-validated argument: the Dart
VM build does not accept one at all (it comes from the environment or the
credentials file), and the npm build registers `onvif_connect` with
`validateArguments: false` and validates in-handler. Errors name the offending
field only.

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
