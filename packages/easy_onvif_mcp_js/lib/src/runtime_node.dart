// The Node.js implementation of [McpRuntime].
//
// Replaces the two things `dart compile js` cannot inherit from the VM: stdio
// (no `dart:io`, so `process.stdin`/`process.stdout` via JS interop) and HTTP
// (Dio's compiled default adapter is `XMLHttpRequest`, which Node does not
// provide). Discovery reuses the existing `node:dgram` probe rather than
// re-implementing WS-Discovery.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dio/dio.dart';
import 'package:easy_onvif_mcp/easy_onvif_mcp.dart';
import 'package:stream_channel/stream_channel.dart';

// The Node transports already proven by `easy-onvif-node`. `easy_onvif_js` is
// a workspace-internal, `publish_to: none` package with no public barrel for
// these, so reaching into `src/` is the cheaper option versus duplicating the
// fetch and dgram bindings.
// ignore_for_file: implementation_imports
import 'package:easy_onvif_js/src/node/node_fetch_adapter.dart';
import 'package:easy_onvif_js/src/node/node_multicast_probe.dart';

import 'node_interop.dart';

/// Host services for the MCP server running as a compiled JS process.
final class NodeMcpRuntime implements McpRuntime {
  @override
  StreamChannel<String> stdioChannel() {
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

  @override
  void log(String message) => logError(message);

  @override
  String? env(String name) => getEnvVar(name);

  @override
  Dio buildDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..httpClientAdapter = NodeFetchAdapter();

  @override
  Future<List<Map<String, dynamic>>> probe(int seconds) async {
    final multicastProbe = NodeMulticastProbe(timeoutSeconds: seconds);
    await multicastProbe.probe();
    return [for (final match in multicastProbe.matches) match.toJson()];
  }

  /// Always null: an `npx` process has no reliable filesystem home, so the
  /// Node target is configured through `ONVIF_HOST` / `ONVIF_USERNAME` /
  /// `ONVIF_PASSWORD` only. The Dart VM target does read
  /// `~/.onvif/credentials.json`.
  @override
  Future<Map<String, String>?> readCredentials() async => null;

  /// A stdin chunk is a Buffer, or a string if the host set an encoding.
  static String _decode(JSAny chunk) {
    if (chunk.isA<JSString>()) return (chunk as JSString).toDart;
    final buffer = chunk as JSObject;
    final toString = buffer['toString'] as JSFunction;
    return (toString.callAsFunction(buffer, 'utf8'.toJS) as JSString).toDart;
  }
}
