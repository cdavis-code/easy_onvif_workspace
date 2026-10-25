/// MCP server exposing ONVIF device control over stdio.
///
/// The exports here are all host-agnostic: the tool registry, the server, and
/// the [McpRuntime] seam.  A target supplies a runtime implementation —
/// `package:easy_onvif_mcp/io.dart` for the Dart VM, or the Node.js runtime in
/// `package:easy_onvif_mcp_js` for the `dart compile js` build.
library;

export 'src/mcp_runtime.dart';
export 'src/onvif_mcp_server.dart';
export 'src/onvif_tools.dart';
export 'src/tool_defs.dart';
