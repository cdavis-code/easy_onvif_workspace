# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0]

### Added
- Initial release: a stdio MCP server for ONVIF devices on top of `easy_onvif`.
- Host-agnostic tool registry (`buildOnvifTools`) shared by the Dart VM binary
  and the `npx easy-onvif-mcp` Node.js bundle via the `McpRuntime` seam.
- Connection tools (`onvif_connect`, `onvif_disconnect`, `onvif_status`) plus
  WS-Discovery (`onvif_probe`).
- Read-only device management, media, imaging, recording, replay and search
  tools, and the PTZ movement/preset set.
- Credentials from `ONVIF_HOST` / `ONVIF_USERNAME` / `ONVIF_PASSWORD` or the
  `easy_onvif_cli` `~/.onvif/credentials.json`.
- Device-mutating operations (reboot, user management, network writes) are
  intentionally not exposed.
