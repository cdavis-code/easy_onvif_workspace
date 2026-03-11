import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:easy_onvif/media1.dart';
import 'package:easy_onvif/util.dart';

import 'onvif_helper_command.dart';

class OnvifMedia1Command extends Command {
  @override
  String get description => 'Media ver10 commands.';

  @override
  String get name => 'media1';

  OnvifMedia1Command() {
    addSubcommand(OnvifGetAudioSourcesMediaCommand());
    addSubcommand(OnvifGetMetadataConfiguration1MediaCommand());
    addSubcommand(OnvifGetMetadataConfigurations1MediaCommand());
    addSubcommand(OnvifGetProfileMediaCommand());
    addSubcommand(OnvifGetProfiles1MediaCommand());
    addSubcommand(OnvifGetServiceCapabilities1MediaCommand());
    addSubcommand(OnvifGetSnapshotUri1MediaCommand());
    addSubcommand(OnvifGetStreamUri1MediaCommand());
    addSubcommand(OnvifGetVideoSourcesMediaCommand());
    addSubcommand(OnvifStartMulticastStreaming1MediaCommand());
    addSubcommand(OnvifStopMulticastStreaming1MediaCommand());
  }
}

///This command lists all available physical audio inputs of the device.
class OnvifGetAudioSourcesMediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This command lists all available physical audio inputs of the device.';

  @override
  String get name => 'get-audio-sources';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final audioSources = await media.media1.getAudioSources();

      print(audioSources);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// The GetMetadataConfiguration command fetches the metadata configuration if
/// the metadata token is known.
class OnvifGetMetadataConfiguration1MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'The GetMetadataConfiguration command fetches the metadata configuration if the metadata token is known.';

  @override
  String get name => 'get-metadata-configuration';

  OnvifGetMetadataConfiguration1MediaCommand() {
    argParser.addOption(
      'configuration-token',
      abbr: 't',
      valueHelp: 'string',
      mandatory: true,
      help: 'Token of the requested metadata configuration.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final metadataConfiguration = await media.media1.getMetadataConfiguration(
        argResults!['configuration-token'],
      );

      print(json.encode(metadataConfiguration));
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// This operation returns the available options (supported values and ranges
/// for metadata configuration parameters) for changing the metadata
/// configuration.
class OnvifGetMetadataConfigurations1MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This operation returns the available options (supported values and ranges for metadata configuration parameters) for changing the metadata configuration.';

  @override
  String get name => 'get-metadata-configurations';

  OnvifGetMetadataConfigurations1MediaCommand() {
    argParser
      ..addOption(
        'configuration-token',
        valueHelp: 'string',
        help:
            'Optional metadata configuration token that specifies an existing configuration that the options are intended for.',
      )
      ..addOption(
        'profile-token',
        valueHelp: 'string',
        help:
            'Optional ProfileToken that specifies an existing media profile that the options shall be compatible with.',
      );
  }
  @override
  void run() async {
    await initializeOnvif();

    try {
      final metadataConfigurations = await media.media1
          .getMetadataConfigurations(
            configurationToken: argResults?['configuration-token'],
            profileToken: argResults?['profile-token'],
          );

      print(metadataConfigurations);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// If the profile token is already known, a profile can be fetched through the
/// GetProfile command.
class OnvifGetProfileMediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'If the profile token is already known, a profile can be fetched through the GetProfile command.';

  @override
  String get name => 'get-profile';

  OnvifGetProfileMediaCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'string',
      mandatory: true,
      help: 'Token of the requested media profile.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final profile = await media.media1.getProfile(
        argResults!['profile-token'],
      );

      print(profile);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Any endpoint can ask for the existing media profiles of a device using the
/// GetProfiles command. Pre-configured or dynamically configured profiles can
/// be retrieved using this command. This command lists all configured profiles
/// in a device. The client does not need to know the media profile in order to
/// use the command.
class OnvifGetProfiles1MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Any endpoint can ask for the existing media profiles of a device using the GetProfiles command. Pre-configured or dynamically configured profiles can be retrieved using this command. This command lists all configured profiles in a device. The client does not need to know the media profile in order to use the command.';

  @override
  String get name => 'get-profiles';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final profiles = await media.media1.getProfiles();

      print(profiles);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Returns the capabilities of the media service. The result is returned in a
/// typed answer.
class OnvifGetServiceCapabilities1MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Returns the capabilities of the media service. The result is returned in a typed answer.';

  @override
  String get name => 'get-service-capabilities';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final mediaServiceCapabilities = await media.media1
          .getServiceCapabilities();

      print(mediaServiceCapabilities);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the
/// device. The returned URI shall remain valid indefinitely even if the profile
/// is changed. The ValidUntilConnect, ValidUntilReboot and Timeout Parameter
/// shall be set accordingly (ValidUntilConnect=false, ValidUntilReboot=false,
/// timeout=PT0S). The URI can be used for acquiring a JPEG image through a HTTP
/// GET operation. The image encoding will always be JPEG regardless of the
/// encoding setting in the media profile. The Jpeg settings (like resolution or
/// quality) may be taken from the profile if suitable. The provided image will
/// be updated automatically and independent from calls to GetSnapshotUri.
class OnvifGetSnapshotUri1MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.';

  @override
  String get name => 'get-snapshot-uri';

  OnvifGetSnapshotUri1MediaCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final mediaUri = await media.media1.getSnapshotUri(
        argResults!['profile-token'],
      );

      print(mediaUri);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// This operation requests a URI that can be used to initiate a live media
/// stream using RTSP as the control protocol. The returned URI shall remain
/// valid indefinitely even if the profile is changed. The ValidUntilConnect,
/// ValidUntilReboot and Timeout Parameter shall be set accordingly
/// (ValidUntilConnect=false, ValidUntilReboot=false, timeout=PT0S).
///
/// The correct syntax for the StreamSetup element for these media stream setups
/// defined in 5.1.1 of the streaming specification are as follows:
/// - RTP unicast over UDP: StreamType = "RTP_unicast", TransportProtocol =
///   "UDP"
/// - RTP over RTSP over HTTP over TCP: StreamType = "RTP_unicast",
///   TransportProtocol = "HTTP"
/// - RTP over RTSP over TCP: StreamType = "RTP_unicast", TransportProtocol =
///   "RTSP"
///
/// If a multicast stream is requested at least one of
/// VideoEncoderConfiguration, AudioEncoderConfiguration and
/// MetadataConfiguration shall have a valid multicast setting.
///
/// For full compatibility with other ONVIF services a device should not
/// generate Uris longer than 128 octets.
class OnvifGetStreamUri1MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This operation requests a URI that can be used to initiate a live media stream using RTSP as the control protocol';

  @override
  String get name => 'get-stream-uri';

  OnvifGetStreamUri1MediaCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help:
            'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
      )
      ..addOption(
        'stream-setup-stream',
        defaultsTo: 'RTP-Unicast',
        valueHelp: 'stream type',
        allowed: [
          'RTP-Unicast',
          'RTP-Multicast',
        ], // ['UDP', 'TCP', 'RTSP', 'HTTP'],
        help: 'Defines if a multicast or unicast stream is requested',
      )
      ..addOption(
        'stream-setup-transport-protocol',
        defaultsTo: 'RTSP',
        valueHelp: 'transport protocol',
        allowed: ['UDP', 'TCP', 'RTSP', 'HTTP'],
        help:
            'Defines the network protocol for streaming, either UDP=RTP/UDP, RTSP=RTP/RTSP/TCP or HTTP=RTP/RTSP/HTTP/TCP',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final mediaUri = await media.media1.getStreamUri(
        argResults!['profile-token'],
        streamSetup: StreamSetup(
          stream: argResults!['stream-setup-stream'],
          transport: Transport(
            protocol: argResults!['stream-setup-transport-protocol'],
          ),
        ),
      );

      print(mediaUri);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// This command lists all available physical video inputs of the device.
class OnvifGetVideoSourcesMediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This command lists all available physical video inputs of the device.';

  @override
  String get name => 'get-video-sources';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final videoSources = await media.media1.getVideoSources();

      print(videoSources);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// This command starts multicast streaming using a specified media profile of a
/// device. Streaming continues until StopMulticastStreaming is called for the
/// same Profile. The streaming shall continue after a reboot of the device
/// until a StopMulticastStreaming request is received. The multicast address,
/// port and TTL are configured in the VideoEncoderConfiguration,
/// AudioEncoderConfiguration and MetadataConfiguration respectively.
class OnvifStartMulticastStreaming1MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This command starts multicast streaming using a specified media profile of a device.';

  @override
  String get name => 'start-multicast-streaming';

  OnvifStartMulticastStreaming1MediaCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await media.media1.startMulticastStreaming(argResults!['profile-token']);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// This command stop multicast streaming using a specified media profile of a device.
class OnvifStopMulticastStreaming1MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This command stop multicast streaming using a specified media profile of a device.';

  @override
  String get name => 'stop-multicast-streaming';

  OnvifStopMulticastStreaming1MediaCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'The ProfileToken element indicates the media profile to use and will define the source and dimensions of the snapshot.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await media.media1.stopMulticastStreaming(argResults!['profile-token']);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}
