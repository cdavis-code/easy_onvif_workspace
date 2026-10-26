/// Dart VM host wiring for the MCP server.
///
/// Kept out of the main barrel so the `dart compile js` entry, which cannot
/// import `dart:io`, still shares the server class and its tool annotations.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_onvif/probe.dart';

import 'src/easy_onvif_mcp_server.dart';

/// Points the server's host hooks at Dart VM facilities: real environment,
/// the `easy_onvif_cli` credentials file and the io multicast probe.
void configureVmHooks() {
  stderrWriteln = stderr.writeln;
  EasyOnvifMcpServer.envReader = (name) => Platform.environment[name];
  EasyOnvifMcpServer.dioFactory = () => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  EasyOnvifMcpServer.probeHook = (seconds) async {
    final multicastProbe = MulticastProbe(timeout: seconds);
    await multicastProbe.probe();
    return [for (final match in multicastProbe.onvifDevices) match.toJson()];
  };
  EasyOnvifMcpServer.credentialsHook = _readCredentialsFile;
}

const String _configPathEnvVar = 'ONVIF_CONFIG_FILE';

/// Reads `$ONVIF_CONFIG_FILE` or the `easy_onvif_cli` default
/// `$HOME/.onvif/credentials.json`, when present.
Future<Map<String, String>?> _readCredentialsFile() async {
  final file = File(_configPath());
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) return null;
    return {
      for (final entry in decoded.entries)
        if (entry.value is String) entry.key.toString(): entry.value as String,
    };
  } on FormatException {
    return null;
  }
}

String _configPath() {
  final override = Platform.environment[_configPathEnvVar];
  if (override != null && override.isNotEmpty) return override;
  return '${Platform.environment['HOME']}/.onvif/credentials.json';
}
