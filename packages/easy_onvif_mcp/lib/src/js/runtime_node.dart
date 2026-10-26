/// Node.js host wiring for the MCP server.
///
/// Replaces the three things `dart compile js` cannot inherit from the VM:
/// stdio (no `dart:io`, so `process.stdin`/`process.stdout` via JS interop),
/// HTTP (Dio's compiled default adapter is `XMLHttpRequest`, which Node does
/// not provide) and WS-Discovery ([NodeMulticastProbe] over `node:dgram`).
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dio/dio.dart';
import 'package:easy_onvif/node.dart';
import 'package:stream_channel/stream_channel.dart';

import '../easy_onvif_mcp_server.dart';
import 'node_interop.dart';

/// Points the server's host hooks at Node.js facilities.
void configureNodeHooks() {
  stderrWriteln = logError;
  EasyOnvifMcpServer.envReader = getEnvVar;
  EasyOnvifMcpServer.dioFactory = () => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..httpClientAdapter = NodeFetchAdapter();
  EasyOnvifMcpServer.probeHook = (seconds) async {
    final multicastProbe = NodeMulticastProbe(timeoutSeconds: seconds);
    await multicastProbe.probe();
    return [for (final match in multicastProbe.matches) match.toJson()];
  };
  // Credentials come from the environment only: an `npx` process has no
  // reliable filesystem home. The Dart VM entry reads
  // `~/.onvif/credentials.json`.
}

/// A line-framed stdio channel over `process.stdin` / `process.stdout`.
StreamChannel<String> nodeStdioChannel() {
  final input = StreamController<String>();
  final output = StreamController<String>();

  // stdin emits arbitrary-sized chunks, so lines have to be reassembled
  // across boundaries — a single JSON-RPC message can arrive split.
  var buffer = '';

  process.stdin.on(
    'data',
    ((JSAny chunk) {
      buffer += _decode(chunk);
      while (buffer.contains('\n')) {
        final cut = buffer.indexOf('\n');
        var line = buffer.substring(0, cut);
        buffer = buffer.substring(cut + 1);
        if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
        if (line.isNotEmpty) input.add(line);
      }
    }).toJS,
  );

  process.stdin.on(
    'end',
    (() {
      // A final message with no trailing newline still has to be delivered.
      var tail = buffer;
      if (tail.endsWith('\r')) tail = tail.substring(0, tail.length - 1);
      if (tail.isNotEmpty) input.add(tail);
      buffer = '';
      input.close();
    }).toJS,
  );

  output.stream.listen((message) => process.stdout.write('$message\n'.toJS));

  return StreamChannel<String>(input.stream, output.sink);
}

/// A stdin chunk is a Buffer, or a string if the host set an encoding.
String _decode(JSAny chunk) {
  if (chunk.isA<JSString>()) return (chunk as JSString).toDart;
  final buffer = chunk as JSObject;
  final toString = buffer['toString'] as JSFunction;
  return (toString.callAsFunction(buffer, 'utf8'.toJS) as JSString).toDart;
}
