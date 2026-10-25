// Entry point compiled by `dart compile js` into the `easy-onvif-mcp` runtime.
//
// This is the whole Node.js side of the server: hand the shared
// [OnvifMcpServer] a Node runtime and let it serve stdio. Every tool, the
// protocol handling and the credential logic live in `easy_onvif_mcp`.
library;

import 'package:easy_onvif_mcp/easy_onvif_mcp.dart';

import 'src/runtime_node.dart';

/// Reported to MCP clients as the server version. Keep in sync with
/// `pubspec.yaml` and `npm/easy-onvif-mcp/package.json`.
const String serverVersion = '0.1.1';

Future<void> main() async {
  final server = OnvifMcpServer(NodeMcpRuntime(), serverVersion);
  await server.done;
}
