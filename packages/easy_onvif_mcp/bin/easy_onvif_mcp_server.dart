// Entry point for the ONVIF MCP stdio server.
//
// Usage:
//   dart run bin/easy_onvif_mcp_server.dart
//
// Credentials come from ONVIF_HOST / ONVIF_USERNAME / ONVIF_PASSWORD, or the
// `easy_onvif_cli` config file (`~/.onvif/credentials.json`, overridable with
// ONVIF_CONFIG_FILE).  Nothing is read until the first tool call, so the server
// always starts, and `onvif_connect` can be used to target a device explicitly.
library;

import 'package:easy_onvif_mcp/easy_onvif_mcp.dart';
import 'package:easy_onvif_mcp/io.dart';

/// Reported to MCP clients as the server version.  Keep in sync with
/// `pubspec.yaml`.
const String serverVersion = '0.1.0';

Future<void> main(List<String> args) async {
  final server = OnvifMcpServer(IoMcpRuntime(), serverVersion);
  await server.done;
}
