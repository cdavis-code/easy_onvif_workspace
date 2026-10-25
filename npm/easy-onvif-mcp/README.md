# easy-onvif-mcp

An [MCP](https://modelcontextprotocol.io) server for ONVIF IP cameras and NVRs,
compiled from Dart with `dart2js`. No install needed — run it with `npx`:

```sh
npx -y easy-onvif-mcp
```

It speaks MCP over stdio, so it is launched by the client rather than by hand.
Register it with a Claude Desktop / OpenCode / any MCP host config:

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

## Configuration

Set `ONVIF_HOST` / `ONVIF_USERNAME` / `ONVIF_PASSWORD` as above, or leave them
out and call the `onvif_connect` tool with the device credentials. Under `npx`
there is no reliable filesystem home, so the `~/.onvif/credentials.json` file
used by `easy_onvif_cli` is only read by the Dart VM build of this server.

## What it can do

Read-only device introspection (manufacturer, firmware, services, capabilities,
network settings, users, relay outputs), media (profiles, RTSP stream URIs,
snapshot URIs, video/audio sources), PTZ (presets, absolute / relative /
continuous moves, stop, single-step directions and zoom), imaging status,
recordings, replay URIs and recording search — plus `onvif_probe` to find
cameras via WS-Discovery.

Device-mutating operations (reboot, user management, hostname / DNS / NTP /
IP-filter writes) are deliberately not exposed.

See the [`easy_onvif_mcp`](https://pub.dev/packages/easy_onvif_mcp) package for
the full tool list and the source of truth this bundle is compiled from.

## Build / provenance

Everything here is generated from `packages/easy_onvif_mcp` + `packages/easy_onvif_mcp_js`
in the [`easy_onvif_workspace`](https://github.com/cdavis-code/easy_onvif_workspace)
monorepo. `bin/easy-onvif-mcp.js` is a hand-maintained Node wrapper that
polyfills the globals the compiled bundle needs; `dist/easy_onvif_mcp.runtime.js`
is the `dart compile js -O4` output.

```sh
# from the repo root
melos run build:npm:mcp
npm test --prefix npm/easy-onvif-mcp
```

## License

MIT
