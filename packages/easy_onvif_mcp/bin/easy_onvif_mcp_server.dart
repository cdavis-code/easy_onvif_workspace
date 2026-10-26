/// Entry point for the ONVIF MCP stdio server.
///
/// Runs the dispatcher generated from the `@Tool` annotations on
/// [EasyOnvifMcpServer], after pointing its host hooks at the Dart VM.
///
/// Usage:
///   dart run bin/easy_onvif_mcp_server.dart        # serve MCP over stdio
///   dart run bin/easy_onvif_mcp_server.dart --version
///   dart run bin/easy_onvif_mcp_server.dart --help
///
/// Regenerate the dispatcher with:
///   dart run build_runner build
library;

import 'dart:io' as io;

import 'package:dart_mcp/stdio.dart';
import 'package:easy_onvif_mcp/meta.dart';
import 'package:easy_onvif_mcp/src/easy_onvif_mcp_server.mcp.dart';
import 'package:easy_onvif_mcp/vm.dart';

const String _usage =
    'easy-onvif-mcp — MCP stdio server for ONVIF cameras and NVRs.\n'
    '\n'
    'Runs over stdio; launch it from an MCP host, not a terminal. It reads\n'
    'credentials from ONVIF_HOST / ONVIF_USERNAME / ONVIF_PASSWORD or\n'
    '~/.onvif/credentials.json and speaks newline-delimited JSON-RPC on stdin\n'
    'and stdout.\n'
    '\n'
    'Options:\n'
    '  -h, --help     Show this usage information.\n'
    '  -v, --version  Show the server version.\n';

Future<void> main(List<String> args) async {
  // The stdio loop reads stdin forever, so the flags Homebrew's `brew test`
  // and a human both reach for must short-circuit before the server starts.
  if (args.contains('--help') || args.contains('-h')) {
    io.stdout.write(_usage);
    return;
  }
  if (args.contains('--version') || args.contains('-v')) {
    io.stdout.writeln('$serverName $serverVersion');
    return;
  }

  configureVmHooks();
  final server = MCPServerWithTools(
    stdioChannel(input: io.stdin, output: io.stdout),
  );
  await server.done;
}
