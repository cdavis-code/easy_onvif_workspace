/// Minimal Node.js bindings for the compiled MCP server.
///
/// Only what the stdio transport and the host seam actually need: `process`
/// streams and environment, plus `console.error` for diagnostics. Written
/// against `dart:js_interop` so it survives `dart compile js`, where
/// `dart:io` does not exist.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('process')
external NodeProcess get process;

extension type NodeProcess(JSObject _) implements JSObject {
  external NodeStream get stdin;
  external NodeStream get stdout;
  external NodeStream get stderr;
  external JSObject get env;
  external void on(String event, JSFunction callback);
  external void exit(int code);
}

extension type NodeStream(JSObject _) implements JSObject {
  external void on(String event, JSFunction callback);
  external void write(JSAny data);
}

/// Reads an environment variable from `process.env`, or null when unset.
String? getEnvVar(String key) {
  final value = process.env[key];
  if (value == null || value.isUndefined) return null;
  final text = (value as JSString).toDart;
  return text.isEmpty ? null : text;
}

/// Writes a line to the process stderr — never stdout, which carries the
/// newline-delimited JSON-RPC stream.
void logError(String message) => console.error(message.toJS);

@JS('console')
external NodeConsole get console;

extension type NodeConsole(JSObject _) implements JSObject {
  external void error(JSAny? message);
}
