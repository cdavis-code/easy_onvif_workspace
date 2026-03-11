import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/media1.dart' as m1;
import 'package:easy_onvif/media2.dart' as m2;
import 'package:easy_onvif/soap.dart' as soap;
import 'package:easy_onvif/src/model/media1/stream_setup.dart';
import 'package:easy_onvif/src/model/media1/transport.dart';
import 'package:easy_onvif/util.dart';
import 'package:loggy/loggy.dart';

import 'media1.dart';
import 'media2.dart';

/// Real-time video and audio streaming configurations are controlled using
/// media profiles. A media profile maps a video and/or audio source to a video
/// and/or an audio encoder, PTZ and analytics configurations.
class Media with UiLoggy {
  final soap.Transport transport;

  final MediaSupportLevel _mediaSupportLevel;

  final Media1? _media1;
  final Media2? _media2;

  Media1 get media1 => _media1 ?? (throw NotSupportedException());
  Media2 get media2 => _media2 ?? (throw NotSupportedException());

  MediaSupportLevel get mediaSupportLevel => _mediaSupportLevel;

  Media({required this.transport, Media1? media1, Media2? media2})
    : _media1 = media1,
      _media2 = media2,
      _mediaSupportLevel = Media.getMediaSupportLevel(media1, media2);

  static MediaSupportLevel getMediaSupportLevel(
    Media1? media1,
    Media2? media2,
  ) {
    if (media1 != null && media2 != null) return MediaSupportLevel.both;

    if (media1 == null && media2 != null) return MediaSupportLevel.two;

    if (media1 != null && media2 == null) return MediaSupportLevel.one;

    return MediaSupportLevel.none;
  }

  /// This command lists all available physical audio inputs of the device.
  Future<List<m1.AudioSource>> getAudioSources() async =>
      _mediaSupportLevel == MediaSupportLevel.two
      ? throw NotSupportedException()
      : media1.getAudioSources();

  /// The GetMetadataConfiguration command fetches the metadata configuration if
  /// the metadata token is known.
  Future<MetadataConfiguration?> getMetadataConfiguration(
    String configurationToken,
  ) async => _mediaSupportLevel == MediaSupportLevel.two
      ? throw NotSupportedException()
      : media1.getMetadataConfiguration(configurationToken);

  /// This operation lists all existing metadata configurations. The client need
  /// not know anything apriori about the metadata in order to use the command.
  Future<List<MetadataConfiguration>> getMetadataConfigurations({
    String? configurationToken,
    String? profileToken,
  }) async => _mediaSupportLevel == MediaSupportLevel.one
      ? media1.getMetadataConfigurations()
      : media2.getMetadataConfigurations(
          configurationToken: configurationToken,
          profileToken: profileToken,
        );

  /// If the profile token is already known, a profile can be fetched through
  /// the [getProfile] command.
  Future<m1.Profile> getProfile(String profileToken) async =>
      _mediaSupportLevel == MediaSupportLevel.two
      ? throw NotSupportedException()
      : media1.getProfile(profileToken);

  /// Any endpoint can ask for the existing media profiles of a device using the
  /// GetProfiles command. Pre-configured or dynamically configured profiles can
  /// be retrieved using this command. This command lists all configured
  /// profiles in a device. The client does not need to know the media profile
  /// in order to use the command.
  Future<List<m1.Profile>?> getProfiles1({
    String? referenceToken,
    List<String>? type,
  }) async => _mediaSupportLevel == MediaSupportLevel.one
      ? media1.getProfiles()
      : throw NotSupportedException();

  /// Retrieve the profile with the specified token or all defined media
  /// profiles.
  /// - If no Type is provided the returned profiles shall contain no
  ///   configuration information.
  /// - If a single Type with value 'All' is provided the returned profiles
  ///   shall include all associated configurations.
  /// - Otherwise the requested list of configurations shall for each profile
  ///   include the configurations present as Type.
  Future<List<m2.MediaProfile>> getProfiles2({
    String? referenceToken,
    List<String>? type,
  }) async => _mediaSupportLevel == MediaSupportLevel.one
      ? throw NotSupportedException()
      : media2.getProfiles(referenceToken: referenceToken, type: type);

  /// returns a [MixedProfile] which will have fields for [m1.Profile] or
  /// [m2.MediaProfile] depending on what is supported by the device.
  Future<List<MixedProfile>> getProfiles({
    String? referenceToken,
    List<String>? type,
  }) async {
    List<m2.MediaProfile>? mediaProfiles;

    List<m1.Profile>? profiles;

    final mixedProfiles = <MixedProfile>[];

    if (_mediaSupportLevel == MediaSupportLevel.one) {
      profiles = await media1.getProfiles();

      for (var profile in profiles) {
        mixedProfiles.add(MixedProfile.fromProfile(profile));
      }
    } else {
      mediaProfiles = await media2.getProfiles(
        referenceToken: referenceToken,
        type: type,
      );

      for (var mediaProfile in mediaProfiles) {
        mixedProfiles.add(MixedProfile.fromMediaProfile(mediaProfile));
      }
    }

    if (mediaProfiles == null && profiles == null) {
      throw NotSupportedException();
    }

    return mixedProfiles;
  }

  /// Returns the capabilities of the media service. The result is returned in a
  /// typed answer.
  Future<m1.Capabilities1> getServiceCapabilities1() async =>
      _mediaSupportLevel == MediaSupportLevel.one
      ? media1.getServiceCapabilities()
      : throw NotSupportedException();

  /// Returns the capabilities of the media service. The result is returned in a
  /// typed answer.
  Future<m2.Capabilities2> getServiceCapabilities2() async =>
      _mediaSupportLevel == MediaSupportLevel.one
      ? throw NotSupportedException()
      : media2.getServiceCapabilities();

  /// Calls [getServiceCapabilities2].
  Future<m2.Capabilities2> getServiceCapabilities() async =>
      media2.getServiceCapabilities();

  /// A client uses the [getSnapshotUri] command to obtain a JPEG snapshot from
  /// the device. The returned URI shall remain valid indefinitely even if the
  /// profile is changed.
  Future<m1.MediaUri> getSnapshotUri1(
    String profileToken, {
    required StreamSetup streamSetup,
  }) async => _mediaSupportLevel == MediaSupportLevel.one
      ? media1.getSnapshotUri(profileToken)
      : throw NotSupportedException();

  /// A client uses the [getSnapshotUri] command to obtain a JPEG snapshot from
  /// the device. The returned URI shall remain valid indefinitely even if the
  /// profile is changed.
  ///
  /// [profileToken] - the ProfileToken element indicates the media profile to
  /// use and will define the source and dimensions of the snapshot.
  Future<String> getSnapshotUri2(String profileToken) async =>
      _mediaSupportLevel == MediaSupportLevel.one
      ? throw NotSupportedException()
      : media2.getSnapshotUri(profileToken);

  /// Calls [getSnapshotUri2].
  // Future<String> getSnapshotUri(String profileToken) async =>
  //     getSnapshotUri2(profileToken);

  Future<String> getSnapshotUri(String profileToken) async {
    dynamic snapshotUri = _mediaSupportLevel == MediaSupportLevel.one
        ? await media1.getSnapshotUri(profileToken)
        : await media2.getSnapshotUri(profileToken);

    return (snapshotUri is String)
        ? snapshotUri
        : (snapshotUri as m1.MediaUri).uri;
  }

  /// This operation requests a [Uri] that can be used to initiate a live media1
  /// stream using RTSP as the control protocol. The returned URI shall remain
  /// valid indefinitely even if the profile is changed.
  ///
  /// The correct syntax for the StreamSetup element for these media1 stream
  /// setups defined in 5.1.1 of the streaming specification are as follows:
  ///  1. RTP unicast over UDP: StreamType = "RTP-Unicast", TransportProtocol =
  ///  "UDP"
  ///  2. RTP over RTSP over HTTP over TCP: StreamType = "RTP-Unicast",
  ///  TransportProtocol = "HTTP"
  ///  3. RTP over RTSP over TCP: StreamType = "RTP-Unicast",
  ///  TransportProtocol = "RTSP"
  ///
  /// If a multicast stream is requested at least one of
  /// videoEncoderConfiguration, audioEncoderConfiguration and
  /// metadataConfiguration shall have a valid multicast setting.
  ///
  /// For full compatibility with other ONVIF services a device should not
  /// generate Uris longer than 128 octets.
  Future<m1.MediaUri> getStreamUri1(
    String profileToken, {
    required StreamSetup streamSetup,
  }) async => _mediaSupportLevel == MediaSupportLevel.one
      ? media1.getStreamUri(profileToken, streamSetup: streamSetup)
      : throw NotSupportedException();

  /// This operation requests a [Uri] that can be used to initiate a live media1
  /// stream using RTSP as the control protocol. The returned URI shall remain
  /// valid indefinitely even if the profile is changed.
  ///
  /// The correct syntax for the StreamSetup element for these media1 stream
  /// setups defined in 5.1.1 of the streaming specification are as follows:
  ///  1. RTP unicast over UDP: StreamType = "RTP-Unicast", TransportProtocol =
  ///  "UDP"
  ///  2. RTP over RTSP over HTTP over TCP: StreamType = "RTP-Unicast",
  ///  TransportProtocol = "HTTP"
  ///  3. RTP over RTSP over TCP: StreamType = "RTP-Unicast",
  ///  TransportProtocol = "RTSP"
  ///
  /// If a multicast stream is requested at least one of
  /// videoEncoderConfiguration, audioEncoderConfiguration and
  /// metadataConfiguration shall have a valid multicast setting.
  ///
  /// For full compatibility with other ONVIF services a device should not
  /// generate Uris longer than 128 octets.
  Future<String> getStreamUri2(
    String profileToken, {
    String protocol = 'RTSP',
  }) async => _mediaSupportLevel == MediaSupportLevel.one
      ? throw NotSupportedException()
      : media2.getStreamUri(profileToken);

  /// Calls [getStreamUri2].
  Future<String> getStreamUri(String profileToken) async {
    dynamic streamUri = _mediaSupportLevel == MediaSupportLevel.one
        ? await media1.getStreamUri(
            profileToken,
            streamSetup: StreamSetup(
              stream: 'RTP-Unicast',
              transport: Transport(protocol: 'RTSP'),
            ),
          )
        : await media2.getStreamUri(profileToken);

    return (streamUri is String) ? streamUri : (streamUri as m1.MediaUri).uri;
  }

  /// This command lists all available physical video inputs of the device.
  Future<List<m1.VideoSource>> getVideoSources() async =>
      _mediaSupportLevel == MediaSupportLevel.one
      ? media1.getVideoSources()
      : throw NotSupportedException();

  /// This command starts multicast streaming using a specified media profile of
  /// a device. Streaming continues until StopMulticastStreaming is called for
  /// the same Profile. The streaming shall continue after a reboot of the
  /// device until a StopMulticastStreaming request is received. The multicast
  /// address, port and TTL are configured in the VideoEncoderConfiguration,
  /// AudioEncoderConfiguration and MetadataConfiguration respectively.
  ///
  /// [profileToken] - contains the token of the Profile that is used to define
  /// the multicast stream.
  Future<bool> startMulticastStreaming(String profileToken) async =>
      _mediaSupportLevel == MediaSupportLevel.one
      ? media1.startMulticastStreaming(profileToken)
      : media2.startMulticastStreaming(profileToken);

  /// This command stop multicast streaming using a specified media profile of a
  /// device
  ///
  /// [profileToken] - contains the token of the Profile that is used to define
  /// the multicast stream.
  Future<bool> stopMulticastStreaming(String profileToken) async =>
      _mediaSupportLevel == MediaSupportLevel.one
      ? media1.stopMulticastStreaming(profileToken)
      : media2.stopMulticastStreaming(profileToken);
}
