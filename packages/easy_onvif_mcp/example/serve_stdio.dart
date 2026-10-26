// Serve the ONVIF tools to an MCP host over stdio.
//
//   dart run example/serve_stdio.dart
//
// An MCP host normally launches the server and keeps stdin open, so this is
// what `claude_desktop_config.json` / OpenCode would run. To see the tool
// surface without a camera, ask the server directly:
//
//   printf '%s\n' \
//     '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"x","version":"0"}}}' \
//     '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
//     '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
//     | dart run bin/easy_onvif_mcp_server.dart

import 'dart:io' as io;

import 'package:dart_mcp/stdio.dart';
import 'package:easy_onvif_mcp/src/easy_onvif_mcp_server.mcp.dart';
import 'package:easy_onvif_mcp/vm.dart';

Future<void> main(List<String> args) async {
  // Credentials come from ONVIF_HOST / ONVIF_USERNAME / ONVIF_PASSWORD, or
  // ~/.onvif/credentials.json — the file `onvif authorize` writes.
  configureVmHooks();
  final server = MCPServerWithTools(
    stdioChannel(input: io.stdin, output: io.stdout),
  );
  await server.done;
}
