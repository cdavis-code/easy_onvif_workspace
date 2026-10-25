# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0]

### Added
- Node.js `McpRuntime` for `easy_onvif_mcp`: stdio framing over
  `process.stdin` / `process.stdout`, `NodeFetchAdapter`-backed Dio, `node:dgram`
  WS-Discovery, and `process.env` credentials.
- `tool/build_mcp_node.sh` compiling the shared server with
  `dart compile js -O4` and staging it into `npm/easy-onvif-mcp/dist/`.
- `tool/publish_npm.sh` releasing the `easy-onvif-mcp` npm package on an
  `easy_onvif_mcp_js-v*` tag.
