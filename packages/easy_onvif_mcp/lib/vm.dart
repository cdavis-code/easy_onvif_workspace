/// Dart VM host wiring for the MCP server.
///
/// Kept out of the main barrel so the `dart compile js` entry, which cannot
/// import `dart:io`, still shares the server class and its tool annotations.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_onvif/credentials.dart';
import 'package:easy_onvif/probe.dart';

import 'src/easy_onvif_mcp_server.dart';

/// Points the server's host hooks at Dart VM facilities: real environment,
/// the encrypted credential bundle and the io multicast probe.
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
const String _deviceEnvVar = 'ONVIF_DEVICE';

/// Reads `$ONVIF_CONFIG_FILE` or `$HOME/.onvif/credentials.json`.
///
/// Returns null only when the file does not exist, so the server falls back to
/// `ONVIF_HOST/USERNAME/PASSWORD` exactly as before. A file that exists but
/// cannot be opened (missing key, wrong key, tampering) throws instead of
/// silently degrading to "no credentials", because that error names the fix.
Future<Map<String, String>?> _readCredentialsFile() async {
  final path = _configPath();
  if (!File(path).existsSync()) return null;

  final file = await CredentialStore.readBundle(path);
  final device = file.bundle.resolve(Platform.environment[_deviceEnvVar]);
  return {
    'host': device.host,
    'username': device.username,
    'password': device.password,
  };
}

String _configPath() {
  final override = Platform.environment[_configPathEnvVar];
  if (override != null && override.isNotEmpty) return override;
  return '${Platform.environment['HOME']}/.onvif/credentials.json';
}
