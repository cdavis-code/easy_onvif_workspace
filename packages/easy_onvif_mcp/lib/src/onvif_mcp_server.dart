/// The ONVIF MCP server: one stdio JSON-RPC loop, one tool registry, one
/// live device connection — shared by the Dart VM and the `dart compile js`
/// Node.js builds.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:easy_onvif/onvif.dart';
import 'package:loggy/loggy.dart';

import 'mcp_runtime.dart';
import 'onvif_tools.dart';
import 'tool_defs.dart';

/// The environment variable holding the device host (optionally `host:port`).
const String envHost = 'ONVIF_HOST';

/// The environment variable holding the device username.
const String envUsername = 'ONVIF_USERNAME';

/// The environment variable holding the device password.
const String envPassword = 'ONVIF_PASSWORD';

/// Routes every tool call through the shared [ToolDef] registry while
/// owning the device connection and the host seam.
base class OnvifMcpServer extends MCPServer with ToolsSupport {
  static const String serverName = 'easy-onvif-mcp';

  static const String _defaultInstructions =
      'ONVIF camera and NVR control server. Call onvif_connect once (or set '
      '$envHost / $envUsername / $envPassword), then use the onvif_* tools to '
      'inspect the device, resolve media URIs, and drive PTZ.';

  final McpRuntime _runtime;

  /// The live device connection. Held here because tool handlers are invoked
  /// per request and reconnecting for every call would cost two SOAP round
  /// trips each time.
  Onvif? _client;

  /// In-flight connection attempt, so a burst of concurrent tool calls
  /// triggers a single [Onvif.connect] rather than a herd.
  Future<Onvif>? _connectFlight;

  /// Tail of the dispatch queue.
  ///
  /// ponytail: `Transport.timeDelta` and `Transport.builder` are *static* in
  /// `easy_onvif`, so two in-flight SOAP requests corrupt each other's
  /// WS-Security timestamp and XML fragment. Serializing every call fixes
  /// that at the cost of throughput, and pins this server to one device.
  /// Revisit only if the core grows per-instance transport state.
  Future<void> _dispatchTail = Future<void>.value();

  OnvifMcpServer(McpRuntime runtime, String version, {String? instructions})
    : _runtime = runtime,
      super.fromStreamChannel(
        runtime.stdioChannel(),
        implementation: Implementation(name: serverName, version: version),
        instructions: instructions ?? _defaultInstructions,
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

  /// The host adapter this server logs, probes and builds HTTP clients with.
  McpRuntime get runtime => _runtime;

  /// Whether a device connection is currently held.
  bool get hasClient => _client != null;

  /// Runs [tool]'s handler serialized against all other tool calls and turns
  /// its return value (or the thrown error) into a [CallToolResult].
  Future<CallToolResult> _invoke(ToolDef tool, CallToolRequest request) async {
    final args = request.arguments ?? const <String, dynamic>{};
    try {
      final value = await _serialized(
        () async => await tool.dispatch(args, this),
      );
      return CallToolResult(
        content: [TextContent(text: jsonEncode(_encode(value)))],
      );
    } catch (error, stack) {
      // stderr only: stdout carries the framed JSON-RPC stream.
      _runtime.log('$serverName: ${tool.name} failed: $error\n$stack');
      return CallToolResult(
        content: [TextContent(text: '${tool.name} failed: $error')],
        isError: true,
      );
    }
  }

  /// Queues [body] behind every previously dispatched tool call.
  Future<T> _serialized<T>(Future<T> Function() body) {
    final result = _dispatchTail.then((_) => body());
    // Keep the queue alive even when a call fails.
    _dispatchTail = result.then((_) {}, onError: (_) {});
    return result;
  }

  static Object? _encode(Object? value) => jsonSafe(value);

  // ---------------------------------------------------------------------------
  // Connection lifecycle
  // ---------------------------------------------------------------------------

  /// Connects to [host] with [username] / [password], replacing any existing
  /// connection. `host` may carry a port (`192.168.1.10:8080`) or a scheme.
  Future<Onvif> connectTo({
    required String host,
    required String username,
    required String password,
  }) async {
    await _closeClient();
    final onvif = await Onvif.connect(
      host: host,
      username: username,
      password: password,
      // Logging must never reach stdout, and the SOAP interceptor chain is
      // chatty even at debug level, so silence it entirely.
      logOptions: const LogOptions(LogLevel.off, stackTraceLevel: LogLevel.off),
      printer: _RuntimePrinter(_runtime.log),
      dio: _runtime.buildDio(),
    );
    _client = onvif;
    return onvif;
  }

  /// Closes the current device connection, if any.
  Future<void> disconnect() => _closeClient();

  Future<void> _closeClient() async {
    final client = _client;
    _client = null;
    _connectFlight = null;
    if (client != null) {
      // Dio.close is synchronous; it releases the connection pool.
      client.transport.dio.close(force: true);
    }
  }

  /// The live connection, bootstrapping it from the environment and/or the
  /// `easy_onvif_cli` credentials file when nothing is connected yet.
  ///
  /// Concurrent callers share one attempt.
  Future<Onvif> ensureConnected() {
    final client = _client;
    if (client != null) return Future.value(client);
    return _connectFlight ??= _connectFromEnvironment().whenComplete(() {
      _connectFlight = null;
    });
  }

  Future<Onvif> _connectFromEnvironment() async {
    final credentials = await _resolveCredentials();
    return connectTo(
      host: credentials['host']!,
      username: credentials['username']!,
      password: credentials['password']!,
    );
  }

  /// Merges the config file with the environment, environment winning.
  Future<Map<String, String>> _resolveCredentials() async {
    final resolved = <String, String>{};

    final file = await _runtime.readCredentials();
    if (file != null) resolved.addAll(file);

    final fromEnv = <String, String>{
      if (_runtime.env(envHost) != null) 'host': _runtime.env(envHost)!,
      if (_runtime.env(envUsername) != null)
        'username': _runtime.env(envUsername)!,
      if (_runtime.env(envPassword) != null)
        'password': _runtime.env(envPassword)!,
    };
    resolved.addAll(fromEnv);

    for (final key in ['host', 'username', 'password']) {
      if (resolved[key] == null || resolved[key]!.isEmpty) {
        throw StateError(
          'No $key for the device. Set $envHost / $envUsername / $envPassword '
          'or provide a ~/.onvif/credentials.json, or call onvif_connect.',
        );
      }
    }
    return resolved;
  }
}

/// Sends loggy output to the host's stderr so stdout stays a clean JSON-RPC
/// channel.
final class _RuntimePrinter extends LoggyPrinter {
  _RuntimePrinter(this._sink);

  final void Function(String message) _sink;

  @override
  void onLog(LogRecord record) =>
      _sink('${record.level.name}: ${record.message}');
}
