import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:easy_onvif/credentials.dart';
import 'package:easy_onvif_cli/command.dart';

void main(List<String> arguments) async {
  CommandRunner(
      'onvif',
      'A command line interface for controlling Onvif compliant devices',
    )
    ..argParser.addOption('config-file', defaultsTo: defaultConfigFile.path)
    ..argParser.addOption(
      'log-level',
      allowed: ['all', 'debug', 'info', 'warning', 'error', 'off'],
      defaultsTo: 'off',
    )
    ..argParser.addOption(
      'network-timeout',
      defaultsTo: '20',
      help: 'Timeout in seconds for the request',
    )
    ..argParser.addOption(
      'device',
      help: 'Device id inside the credential file (defaults to its default).',
    )
    ..argParser.addOption(
      'key-file',
      help: 'File holding the 32-byte key (hex or base64).',
    )
    ..argParser.addFlag(
      'prompt',
      negatable: false,
      help: 'Seal credential writes with a passphrase instead of a raw key.',
    )
    ..addCommand(OnvifAuthorizeCommand())
    ..addCommand(OnvifCredentialsCommand())
    ..addCommand(OnvifDebugCommand())
    ..addCommand(OnvifDeviceManagementCommand())
    ..addCommand(OnvifImagingCommand())
    ..addCommand(OnvifMedia1Command())
    ..addCommand(OnvifMedia2Command())
    ..addCommand(OnvifPtzCommand())
    ..addCommand(OnvifProbeCommand())
    ..addCommand(OnvifRecordingsCommand())
    ..addCommand(OnvifReplayCommand())
    ..addCommand(OnvifSearchCommand())
    ..addCommand(OnvifVersionCommand())
    ..run(arguments).catchError((Object error) {
      // Credential problems are operator errors, not bugs: report them without
      // a stack trace and use the exit code the design documents (§8).
      if (error is KeyUnavailableException) {
        stderr.writeln('Error: ${error.message}');
        exit(2);
      }
      if (error is CredentialsFormatException) {
        stderr.writeln('Error: ${error.message}');
        exit(2);
      }
      if (error is! UsageException) throw error;

      print(error);

      exit(64); // Exit code 64 indicates a usage error.
    });
}
