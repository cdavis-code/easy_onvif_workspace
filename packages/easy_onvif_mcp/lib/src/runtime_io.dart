/// The Dart VM implementation of [McpRuntime].
///
/// Kept out of the main barrel so the `dart compile js` target, which cannot
/// import `dart:io`, still shares the server and tool registry.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dart_mcp/stdio.dart' as mcp_stdio;
import 'package:easy_onvif/probe.dart';
import 'package:stream_channel/stream_channel.dart';

import 'mcp_runtime.dart';

/// Stdio, environment and config-file access for a process running on the Dart VM.
final class IoMcpRuntime implements McpRuntime {
  static const _configPathEnvVar = 'ONVIF_CONFIG_FILE';

  @override
  StreamChannel<String> stdioChannel() =>
      mcp_stdio.stdioChannel(input: stdin, output: stdout);

  @override
  void log(String message) => stderr.writeln(message);

  @override
  String? env(String name) => Platform.environment[name];

  @override
  Dio buildDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<List<Map<String, dynamic>>> probe(int seconds) async {
    final multicastProbe = MulticastProbe(timeout: seconds);
    await multicastProbe.probe();
    return [for (final match in multicastProbe.onvifDevices) match.toJson()];
  }

  @override
  Future<Map<String, String>?> readCredentials() async {
    final file = File(_configPath());
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return null;
      return {
        for (final entry in decoded.entries)
          if (entry.value is String)
            entry.key.toString(): entry.value as String,
      };
    } on FormatException {
      return null;
    }
  }

  /// Honours `ONVIF_CONFIG_FILE`, otherwise the `easy_onvif_cli` default of
  /// `$HOME/.onvif/credentials.json`.
  String _configPath() {
    final override = env(_configPathEnvVar);
    if (override != null && override.isNotEmpty) return override;
    return '${env('HOME')}/.onvif/credentials.json';
  }
}
