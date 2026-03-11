import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:easy_onvif/util.dart';

import 'onvif_helper_command.dart';

class OnvifMedia2Command extends Command {
  @override
  String get description => 'Media ver20 commands.';

  @override
  String get name => 'media2';

  OnvifMedia2Command() {
    addSubcommand(OnvifGetMetadataConfigurationOptionsMediaCommand());
    addSubcommand(OnvifGetMetadataConfigurations2MediaCommand());
    addSubcommand(OnvifGetProfiles2MediaCommand());
    addSubcommand(OnvifGetServiceCapabilities2MediaCommand());
    addSubcommand(OnvifGetSnapshotUri2MediaCommand());
    addSubcommand(OnvifGetStreamUri2MediaCommand());
    addSubcommand(OnvifGetVideoEncoderInstancesMediaCommand());
    addSubcommand(OnvifGetVideoEncoderConfigurationsMediaCommand());
    addSubcommand(OnvifGetVideoSourceConfigurationOptionsMediaCommand());
    // addSubcommand(OnvifDeleteProfileMediaCommand());
    addSubcommand(OnvifStartMulticastStreaming2MediaCommand());
    addSubcommand(OnvifStopMulticastStreaming2MediaCommand());
  }
}

/// This operation returns the available options (supported values and ranges
/// for metadata configuration parameters) for changing the metadata
/// configuration.
class OnvifGetMetadataConfigurationOptionsMediaCommand
    extends OnvifHelperCommand {
  @override
  String get description =>
      'This operation returns the available options (supported values and ranges for metadata configuration parameters) for changing the metadata configuration.';

  @override
  String get name => 'get-metadata-configuration-options';

  OnvifGetMetadataConfigurationOptionsMediaCommand() {
    argParser
      ..addOption(
        'configuration-token',
        valueHelp: 'string',
        help: 'Token of the requested configuration.',
      )
      ..addOption(
        'profile-token',
        valueHelp: 'string',
        help:
            'Contains the token of an existing media profile the configurations shall be compatible with.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final metadataConfigurationOptions = await media.media2
          .getMetadataConfigurationOptions(
            configurationToken: argResults?['configuration-token'],
            profileToken: argResults?['profile-token'],
          );

      print(metadataConfigurationOptions);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// By default this operation lists all existing metadata configurations for a
/// device. Provide a profile token to list only configurations that are
/// compatible with the profile. If a configuration token is provided only a
/// single configuration will be returned.
class OnvifGetMetadataConfigurations2MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'By default this operation lists all existing metadata configurations for a device. Provide a profile token to list only configurations that are compatible with the profile. If a configuration token is provided only a single configuration will be returned.';

  @override
  String get name => 'get-metadata-configurations';

  OnvifGetMetadataConfigurations2MediaCommand() {
    argParser
      ..addOption(
        'configuration-token',
        valueHelp: 'string',
        help: 'Token of the requested configuration.',
      )
      ..addOption(
        'profile-token',
        valueHelp: 'string',
        help:
            'Contains the token of an existing media profile the configurations shall be compatible with.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final metadataConfigurations = await media.media2
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

/// Retrieve the profile with the specified token or all defined media profiles.
/// - If no Type is provided the returned profiles shall contain no
///   configuration information.
/// - If a single Type with value 'All' is provided the returned profiles shall
///   include all associated configurations.
/// - Otherwise the requested list of configurations shall for each profile
///   include the configurations present as Type.
class OnvifGetProfiles2MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Retrieve the profile with the specified token or all defined media profiles.';

  @override
  String get name => 'get-profiles';

  OnvifGetProfiles2MediaCommand() {
    argParser
      ..addOption(
        'reference-token',
        valueHelp: 'string',
        help: 'Optional token of the requested profile.',
      )
      ..addOption(
        'type',
        valueHelp: 'comma delimited string',
        allowed: [
          'All',
          'Analytics',
          'AudioSource',
          'AudioDecoder',
          'AudioEncoder',
          'AudioOutput',
          'Metadata',
          'VideoEncoder',
          'VideoSource',
          'PTZ',
        ],
        help:
            'The types shall be provided as defined by tr2:ConfigurationEnumeration.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final profiles = await media.media2.getProfiles(
        referenceToken: argResults?['reference-token'],
        type: argResults?['reference-token'],
      );

      print(profiles);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Returns the capabilities of the media service. The result is returned in a
/// typed answer.
class OnvifGetServiceCapabilities2MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Returns the capabilities of the media service. The result is returned in a typed answer.';

  @override
  String get name => 'get-service-capabilities';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final mediaServiceCapabilities = await media.media2
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
class OnvifGetSnapshotUri2MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'A client uses the GetSnapshotUri command to obtain a JPEG snapshot from the device.';

  @override
  String get name => 'get-snapshot-uri';

  OnvifGetSnapshotUri2MediaCommand() {
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
      final mediaUri = await media.media2.getSnapshotUri(
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
class OnvifGetStreamUri2MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This operation requests a URI that can be used to initiate a live media stream using RTSP as the control protocol';

  @override
  String get name => 'get-stream-uri';

  OnvifGetStreamUri2MediaCommand() {
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
        'protocol',
        defaultsTo: 'RTSP',
        valueHelp: 'transport protocol',
        allowed: [
          'RtspUnicast',
          'RtspMulticast',
          'RTSP',
          'RtspsUnicast',
          'RtspsMulticast',
          'RtspOverHttp',
        ],
        help:
            'The Protocol defines how the encoded data is expected to be streamed to the client',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final mediaUri = await media.media2.getStreamUri(
        argResults!['profile-token'],
        protocol: argResults?['protocol'],
      );

      print(mediaUri);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// The GetVideoEncoderInstances command can be used to request the minimum
/// number of guaranteed video encoder instances (applications) per Video Source
/// Configuration.
class OnvifGetVideoEncoderInstancesMediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'The GetVideoEncoderInstances command can be used to request the minimum number of guaranteed video encoder instances (applications) per Video Source Configuration.';

  @override
  String get name => 'get-video-encoder-instances';

  OnvifGetVideoEncoderInstancesMediaCommand() {
    argParser.addOption(
      'configuration-token',
      mandatory: true,
      valueHelp: 'string',
      help: 'Token of the video source configuration',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final info = await media.media2.getVideoEncoderInstances(
        argResults!['configuration-token'],
      );

      print(info);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// By default this operation lists all existing video encoder configurations
/// for a device. Provide a profile token to list only configurations that are
/// compatible with the profile. If a configuration token is provided only a
/// single configuration will be returned.
class OnvifGetVideoEncoderConfigurationsMediaCommand
    extends OnvifHelperCommand {
  @override
  String get description =>
      'By default this operation lists all existing video encoder configurations for a device.';

  @override
  String get name => 'get-video-encoder-configurations';

  OnvifGetVideoEncoderConfigurationsMediaCommand() {
    argParser
      ..addOption(
        'profile-token',
        abbr: 't',
        valueHelp: 'string',
        help:
            'Contains the token of an existing media profile the configurations shall be compatible with.',
      )
      ..addOption(
        'configuration-token',
        valueHelp: 'string',
        help: 'Token of the requested configuration.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final videoEncoderConfigurations = await media.media2
          .getVideoEncoderConfigurations(
            configurationToken: argResults?['configuration-token'],
            profileToken: argResults?['profile-token'],
          );

      print(videoEncoderConfigurations);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// This operation returns the available options (supported values and ranges
/// for video source configuration parameters) when the video source parameters
/// are reconfigured If a video source configuration is specified, the options
/// shall concern that particular configuration. If a media profile is
/// specified, the options shall be compatible with that media profile.
class OnvifGetVideoSourceConfigurationOptionsMediaCommand
    extends OnvifHelperCommand {
  @override
  String get description =>
      'This operation returns the available options (supported values and ranges for video source configuration parameters) when the video source parameters are reconfigured If a video source configuration is specified, the options shall concern that particular configuration. If a media profile is specified, the options shall be compatible with that media profile.';

  @override
  String get name => 'get-video-source-configuration-options';

  OnvifGetVideoSourceConfigurationOptionsMediaCommand() {
    argParser
      ..addOption(
        'configuration-token',
        valueHelp: 'string',
        help: 'Token of the requested configuration.',
      )
      ..addOption(
        'profile-token',
        valueHelp: 'string',
        help:
            'Contains the token of an existing media profile the configurations shall be compatible with.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final videoSourceConfigurationOptions = await media.media2
          .getVideoSourceConfigurationOptions(
            configurationToken: argResults?['configuration-token'],
            profileToken: argResults?['configuration-token'],
          );

      print(videoSourceConfigurationOptions);
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
class OnvifStartMulticastStreaming2MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This command starts multicast streaming using a specified media profile of a device.';

  @override
  String get name => 'start-multicast-streaming';

  OnvifStartMulticastStreaming2MediaCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'Contains the token of the Profile that is used to define the multicast stream.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await media.media2.startMulticastStreaming(argResults!['profile-token']);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// This command stop multicast streaming using a specified media profile of a device.
class OnvifStopMulticastStreaming2MediaCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'This command stop multicast streaming using a specified media profile of a device.';

  @override
  String get name => 'stop-multicast-streaming';

  OnvifStopMulticastStreaming2MediaCommand() {
    argParser.addOption(
      'profile-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
      help:
          'Contains the token of the Profile that is used to define the multicast stream.',
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      await media.media2.stopMulticastStreaming(argResults!['profile-token']);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}
