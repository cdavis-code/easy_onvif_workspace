import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ansi_escapes/ansi_escapes.dart';
import 'package:archive/archive.dart';
import 'package:args/command_runner.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:easy_onvif/device_management.dart';
import 'package:easy_onvif/media1.dart';
import 'package:easy_onvif/media2.dart';
import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/shared.dart';
import 'package:loggy/loggy.dart';
import 'package:easy_onvif_cli/command.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Generate a refresh token used to authenticate the command line API requests
class OnvifDebugCommand extends Command with UiLoggy {
  @override
  String get description => 'Generate a debug bundle for an Onvif device.';

  @override
  String get name => 'debug';

  final greenPen = AnsiPen()..green(bold: true);

  final bluePen = AnsiPen()..blue(bold: true);

  OnvifDebugCommand() {
    argParser
      ..addOption(
        'output-folder',
        abbr: 'o',
        valueHelp: 'file path',
        help: 'destination folder for debug bundle',
        defaultsTo: 'debug',
      )
      ..addOption(
        'module',
        abbr: 'm',
        valueHelp: 'string',
        allowed: ['all', 'device', 'media1', 'media2', 'ptz'],
        defaultsTo: 'all',
        help: 'Token of the requested metadata configuration.',
      );
  }

  void _showAction(String command) {
    stdout.write(ansiEscapes.cursorNextLine);
    stdout.write('${greenPen('\u{2705}')} $command\n');
  }

  void _showError(String command) {
    stdout.write(ansiEscapes.cursorNextLine);
    stdout.write('${greenPen('\u{274C}')} $command\n');
  }

  void _showSkip(String command) {
    stdout.write(ansiEscapes.cursorNextLine);
    stdout.write('${greenPen('\u{21AA}')} $command\n');
  }

  Future<T?> test<T>(
    String name,
    Future<T> Function() fn, {
    bool skipWhenNull = false,
  }) async {
    try {
      if (skipWhenNull) {
        _showSkip(name);
        return null;
      }

      var value = await fn();

      _showAction(name);

      return value;
    } catch (e) {
      _showError(name);

      loggy.error('$name\n');
      loggy.error(e);
    }

    return null;
  }

  @override
  void run() async {
    var module = argResults!['module'];

    // create temp folder named by device name
    // get responses into xml files named by response type
    // zip up folder and output to --output

    var folderName = argResults?['output-folder'] ?? 'debug';

    if (!p.isAbsolute(folderName)) {
      folderName = p.join(Directory.current.path, folderName);
    }

    final filePath = p.join(folderName, 'debug.txt');

    final zipFile = File(p.join(folderName, 'debug.zip'));

    final config = loadYaml(defaultConfigFile.readAsStringSync());

    // configure device connection
    final onvif = await Onvif.connect(
      host: config['host'],
      username: config['username'],
      password: config['password'],
      logOptions: const LogOptions(
        LogLevel.debug,
        stackTraceLevel: LogLevel.error,
      ),
      printer: FilePrinter(filePath: filePath),
    );

    final random = Random().nextInt(900000) + 100000;

    //
    // test Device Management information
    //

    if (module == 'all' || module == 'device') {
      stdout.write('\n\t${bluePen('Test Device Management module')}\n');

      await test(
        'GetCapabilities',
        () async => await onvif.deviceManagement.getCapabilities(),
      );

      await test(
        'GetDeviceInformation',
        () async => await onvif.deviceManagement.getDeviceInformation(),
      );

      await test(
        'GetDiscoveryMode',
        () async => await onvif.deviceManagement.getDiscoveryMode(),
      );

      await test('GetDns', () async => await onvif.deviceManagement.getDns());

      await test(
        'GetEndpointReference',
        () async => await onvif.deviceManagement.getEndpointReference(),
      );

      await test(
        'GetHostname',
        () async => await onvif.deviceManagement.getHostname(),
      );

      await test(
        'GetNetworkProtocols',
        () async => await onvif.deviceManagement.getNetworkProtocols(),
      );

      await test('GetNtp', () async => await onvif.deviceManagement.getNtp());

      await test(
        'GetServiceCapabilities',
        () async => await onvif.deviceManagement.getServiceCapabilities(),
      );

      await test(
        'GetServices',
        () async => await onvif.deviceManagement.getServices(),
      );

      final storageConfigurations = await test<List<StorageConfiguration>>(
        'GetStorageConfigurations',
        () async => await onvif.deviceManagement.getStorageConfigurations(),
      );

      final storageConfigurationToken = storageConfigurations?.first.token;

      await test(
        'GetStorageConfiguration',
        () async => await onvif.deviceManagement.getStorageConfiguration(
          storageConfigurationToken!,
        ),
        skipWhenNull: storageConfigurationToken == null,
      );

      await test(
        'GetSystemDateAndTime',
        () async => await onvif.deviceManagement.getSystemDateAndTime(),
      );

      await test(
        'GetSystemUris',
        () async => await onvif.deviceManagement.getSystemUris(),
      );

      await test(
        'GetSystemLog',
        () async => await onvif.deviceManagement.getSystemLog('System'),
      );

      await test(
        'GetSystemSupportInformation',
        () async => await onvif.deviceManagement.getSystemSupportInformation(),
      );

      await test(
        'GetUsers',
        () async => await onvif.deviceManagement.getUsers(),
      );

      await test(
        'CreateUsers',
        () async => await onvif.deviceManagement.createUsers([
          User(
            username: 'deleteMe_$random',
            password: 'deleteMe_${random}_',
            userLevel: UserLevel.user,
          ),
        ]),
      );

      await test(
        'DeleteUsers',
        () async =>
            await onvif.deviceManagement.deleteUsers(['deleteMe_$random']),
      );
    }

    //
    // Test Media1 module
    //

    stdout.write('\n\t${bluePen('Retrieving Media1 Token')}\n');

    final media1profiles = await test<List<Profile>>(
      'Media1 - GetProfiles',
      () async => await onvif.media.media1.getProfiles(),
    );

    final media1profileToken = media1profiles?.first.token;

    if (module == 'all' || module == 'media1') {
      stdout.write('\n\t${bluePen('Test Media1 module')}\n');

      await test(
        'GetAudioSources',
        () async => await onvif.media.media1.getAudioSources(),
      );

      final metadataConfigurations = await test<List<MetadataConfiguration>>(
        'GetMetadataConfigurations',
        () async => await onvif.media.media1.getMetadataConfigurations(),
      );

      final metadataConfigurationToken = metadataConfigurations?.first.token;

      await test(
        'GetMetadataConfiguration',
        () async => await onvif.media.media1.getMetadataConfiguration(
          metadataConfigurationToken!,
        ),
        skipWhenNull: metadataConfigurationToken == null,
      );

      await test(
        'GetProfile',
        () async => await onvif.media.media1.getProfile(media1profileToken!),
        skipWhenNull: media1profileToken == null,
      );

      await test(
        'GetServiceCapabilities',
        () async => await onvif.media.media1.getServiceCapabilities(),
      );

      await test(
        'GetSnapshotUri',
        () async =>
            await onvif.media.media1.getSnapshotUri(media1profileToken!),
        skipWhenNull: media1profileToken == null,
      );

      await test(
        'GetStreamUri',
        () async => await onvif.media.media1.getStreamUri(
          media1profileToken!,
          streamSetup: StreamSetup(
            stream: 'RTP-Unicast',
            transport: Transport(protocol: 'RTSP'),
          ),
        ),
        skipWhenNull: media1profileToken == null,
      );

      await test(
        'GetVideoSources',
        () async => await onvif.media.media1.getVideoSources(),
      );

      await test(
        'StartMulticastStreaming',
        () async => await onvif.media.media1.startMulticastStreaming(
          media1profileToken!,
        ),
        skipWhenNull: media1profileToken == null,
      );

      await test(
        'StopMulticastStreaming',
        () async => await onvif.media.media1.stopMulticastStreaming(
          media1profileToken!,
        ),
        skipWhenNull: media1profileToken == null,
      );
    }

    //
    // Test Media2 module
    //

    stdout.write('\n\t${bluePen('Retrieving Media2 Token')}\n');

    final media2profiles = await test<List<MediaProfile>>(
      'Media2 - GetProfiles',
      () async => await onvif.media.media2.getProfiles(),
    );

    final media2profileToken = media2profiles?.first.token;

    if (module == 'all' || module == 'media2') {
      stdout.write('\n\t${bluePen('Test Media2 module')}\n');

      await test(
        'GetMetadataConfigurationOptions',
        () async => await onvif.media.media2.getMetadataConfigurationOptions(),
      );

      await test(
        'GetMetadataConfigurations',
        () async => await onvif.media.media2.getMetadataConfigurations(),
      );

      await test(
        'GetServiceCapabilities',
        () async => await onvif.media.media2.getServiceCapabilities(),
      );

      await test(
        'GetSnapshotUri',
        () async =>
            await onvif.media.media2.getSnapshotUri(media2profileToken!),
        skipWhenNull: media2profileToken == null,
      );

      await test(
        'GetStreamUri',
        () async => await onvif.media.media2.getStreamUri(
          media2profileToken!,
          protocol: 'RTSP',
          streamType: 'RTP-Unicast',
        ),
        skipWhenNull: media2profileToken == null,
      );

      final videoEncoderConfigurationToken = media2profiles
          ?.first
          .configurations
          ?.videoEncoderConfiguration
          ?.token;

      await test(
        'GetVideoEncoderInstances',
        () async => await onvif.media.media2.getVideoEncoderInstances(
          videoEncoderConfigurationToken!,
        ),
        skipWhenNull: videoEncoderConfigurationToken == null,
      );

      final videoSourceConfigurationToken =
          media2profiles?.first.configurations?.videoSourceConfiguration?.token;

      await test(
        'GetVideoSourceConfigurationOptions',
        () async => await onvif.media.media2.getVideoSourceConfigurationOptions(
          configurationToken: videoSourceConfigurationToken!,
        ),
        skipWhenNull: videoSourceConfigurationToken == null,
      );

      await test(
        'GetVideoEncoderConfigurations',
        () async => await onvif.media.media2.getVideoEncoderConfigurations(),
      );

      await test(
        'StartMulticastStreaming',
        () async => await onvif.media.media2.startMulticastStreaming(
          media2profileToken!,
        ),
        skipWhenNull: media2profileToken == null,
      );

      await test(
        'StopMulticastStreaming',
        () async => await onvif.media.media2.stopMulticastStreaming(
          media2profileToken!,
        ),
        skipWhenNull: media2profileToken == null,
      );
    }

    //
    // Test ptz module
    //

    final ptzProfileToken = media1profileToken ?? media2profileToken;

    if (module == 'all' || module == 'ptz') {
      stdout.write('\n\t${bluePen('Test PTZ module')}\n');

      await test(
        'AbsoluteMove',
        () async => await onvif.ptz.absoluteMove(
          ptzProfileToken!,
          position: PtzVector(
            panTilt: Vector2D(x: 0, y: 0),
            zoom: Vector1D(x: 0),
          ),
        ),
        skipWhenNull: ptzProfileToken == null,
      );

      await test(
        'ContinuousMove',
        () async => await onvif.ptz.continuousMove(
          ptzProfileToken!,
          velocity: PtzSpeed(
            panTilt: Vector2D(x: 0.1, y: 0.1),
            zoom: Vector1D(x: 0),
          ),
        ),
        skipWhenNull: ptzProfileToken == null,
      );

      final configurations = await test(
        'GetCompatibleConfigurations',
        () async =>
            await onvif.ptz.getCompatibleConfigurations(ptzProfileToken!),
        skipWhenNull: ptzProfileToken == null,
      );

      await test(
        'GetConfigurationOptions',
        () async => await onvif.ptz.getConfigurationOptions(
          configurations != null ? configurations.first.token : '',
        ),
        skipWhenNull: configurations == null,
      );

      await test(
        'GetServiceCapabilities',
        () async => await onvif.ptz.getServiceCapabilities(),
      );

      await test(
        'GetConfigurations',
        () async => await onvif.ptz.getConfigurations(),
      );
    }

    //
    // Archive results
    //

    print('');

    final archive = Archive();

    archive.addFile(
      ArchiveFile(
        filePath,
        File(filePath).lengthSync(),
        File(filePath).readAsBytesSync(),
      ),
    );

    final spinner = CliSpin(
      text: 'Archiving results',
      spinner: CliSpinners.line,
    ).start(); // Chai

    Timer(Duration(milliseconds: 1000), () {
      // Change spinner color
      spinner.color = CliSpinnerColor.yellow;

      // Change spinner text
      spinner.text = 'Still archiving results ...';
    });

    final zipData = ZipEncoder().encode(archive);

    if (zipFile.existsSync()) {
      zipFile.deleteSync();
    }

    zipFile.writeAsBytesSync(zipData);

    spinner.success('Bundle created successfully.');
  }
}
