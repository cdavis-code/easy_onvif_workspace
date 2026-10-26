/// Package identity, used for the MCP `Implementation` name/version.
///
/// Keep in step with `pubspec.yaml` and `package.json`; `tool/build_node.sh`
/// and the publish scripts assert they agree.
library;

/// The MCP server name reported in the `initialize` handshake.
const String serverName = 'easy-onvif-mcp';

/// The package version, mirroring `pubspec.yaml`.
const String serverVersion = '0.3.0';
