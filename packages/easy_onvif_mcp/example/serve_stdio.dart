// Two ways to use the MCP server: inspect its tool surface, or run it.
//
//   dart run serve_stdio.dart --list-tools   # no camera required
//   dart run serve_stdio.dart                # serve MCP over stdio
//
// An MCP host normally launches the server and keeps stdin open, so the second
// form is what `claude_desktop_config.json` / OpenCode would run. The first is
// a quick way to see what a model would be handed.
// ignore_for_file: avoid_print

import 'package:easy_onvif_mcp/easy_onvif_mcp.dart';
import 'package:easy_onvif_mcp/io.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--list-tools')) {
    final tools = buildOnvifTools();
    print('${tools.length} tools:');
    for (final tool in tools) {
      final required = tool.inputSchema.required ?? const <String>[];
      print(
        '  ${tool.name}${required.isEmpty ? '' : ' (requires ${required.join(', ')})'}',
      );
    }
    return;
  }

  // Credentials come from ONVIF_HOST / ONVIF_USERNAME / ONVIF_PASSWORD, or
  // ~/.onvif/credentials.json — the file `onvif authorize` writes.
  final server = OnvifMcpServer(IoMcpRuntime(), '0.1.0');
  await server.done;
}
