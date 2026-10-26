/// The Node.js MCP server: one stdio JSON-RPC loop over the hand-written
/// registry in `tools.dart`.
///
/// The Dart VM binary runs the dispatcher generated from the `@Tool`
/// annotations instead (see `bin/easy_onvif_mcp_server.dart`); this class
/// exists only because that generated code imports `dart:io`.
library;

import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:stream_channel/stream_channel.dart';

import '../easy_onvif_mcp_server.dart';
import '../json_safe.dart';
import 'tool_defs.dart';
import 'tools.dart';

/// Serves the ONVIF tool registry over an arbitrary [StreamChannel].
base class NodeMcpServer extends MCPServer with ToolsSupport {
  static const String serverName = 'easy-onvif-mcp';

  static const String _instructions =
      'ONVIF camera and NVR control server. Call onvif_connect once (or set '
      '$envHost / $envUsername / $envPassword), then use the onvif_* tools to '
      'inspect the device, resolve media URIs, and drive PTZ.';

  NodeMcpServer(super.channel, {required String version})
    : super.fromStreamChannel(
        implementation: Implementation(name: serverName, version: version),
        instructions: _instructions,
      ) {
    for (final tool in buildOnvifTools()) {
      registerTool(
        Tool(
          name: tool.name,
          description: tool.description,
          inputSchema: tool.inputSchema,
        ),
        (request) => _invoke(tool, request),
        // Tools carrying a credential opt out: dart_mcp's validation failure
        // message quotes the rejected value verbatim.
        validateArguments: tool.validateArguments,
      );
    }
  }

  /// Runs [tool]'s handler and turns its return value (or error) into a
  /// [CallToolResult].
  Future<CallToolResult> _invoke(ToolDef tool, CallToolRequest request) async {
    final args = request.arguments ?? const <String, dynamic>{};
    try {
      // The lock spans the implicit connect and the device request: the static
      // `Transport` state in `easy_onvif` cannot take concurrent SOAP calls.
      final value = await EasyOnvifMcpServer.serializedCall(
        () async => tool.dispatch(args),
      );
      return CallToolResult(
        content: [TextContent(text: jsonEncode(jsonSafe(value)))],
      );
    } catch (error, stack) {
      stderrWriteln('$serverName: ${tool.name} failed: $error\n$stack');
      return CallToolResult(
        content: [TextContent(text: '${tool.name} failed: $error')],
        isError: true,
      );
    }
  }
}
