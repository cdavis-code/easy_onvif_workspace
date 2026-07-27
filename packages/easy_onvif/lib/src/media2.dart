import 'package:easy_onvif/media2.dart';
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' as soap;

import 'operation.dart';

typedef Media2Request = soap.Media2Request;

/// Real-time video and audio streaming configurations are controlled using
/// media profiles. A media profile maps a video and/or audio source to a video
/// and/or an audio encoder, PTZ and analytics configurations. An ONVIF
/// compliant device supporting the media service presents different available
/// profiles depending on its capabilities
///
/// Default Access Policy Definition
/// | | Administrator | Operator | User | Anonymous |
/// | PRE_AUTH | X | X | X | X |
/// | READ_SYSTEM | X | X | X | |
/// | READ_SYSTEM_SENSITIVE | X | X | | |
/// | READ_SYSTEM_SECRET | X | | | |
/// | WRITE_SYSTEM | X | | | |
/// | UNRECOVERABLE | X | | | |
/// | READ_MEDIA | X | X | X | |
/// | ACTUATE | X | X | | |
class Media2 extends Operation {
  Media2({required super.transport, required super.uri});

  /// This operation deletes a profile. Deletion of a profile is only possible
  /// for non-fixed profiles
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> deleteProfile(String referenceToken) async {
    loggy.debug('deleteProfile');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: Media2Request.deleteProfile(referenceToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return responseEnvelope.body.response?.containsKey(
          'DeleteProfileResponse',
        ) ??
        false;
  }

  /// This operation returns the available options (supported values and ranges
  /// for metadata configuration parameters) for changing the metadata
  /// configuration.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<MetadataConfigurationOptions> getMetadataConfigurationOptions({
    String? configurationToken,
    String? profileToken,
  }) async {
    loggy.debug('getMetadataConfigurationOptions');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: Media2Request.getMetadataConfigurationOptions(
          configurationToken: configurationToken,
          profileToken: profileToken,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetMetadataConfigurationOptionsResponse.fromJson(
      responseEnvelope.body.response!,
    ).options;
  }

  /// By default this operation lists all existing metadata configurations for a
  /// device. Provide a profile token to list only configurations that are
  /// compatible with the profile. If a configuration token is provided only a
  /// single configuration will be returned.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<List<MetadataConfiguration>> getMetadataConfigurations({
    String? configurationToken,
    String? profileToken,
  }) async {
    loggy.debug('getMetadataConfigurations');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: Media2Request.getMetadataConfigurations(
          configurationToken: configurationToken,
          profileToken: profileToken,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetMetadataConfigurationsResponse.fromJson(
      responseEnvelope.body.response!,
    ).configurations;
  }

  /// Retrieve the profile with the specified token or all defined media
  /// profiles.
  /// - If no Type is provided the returned profiles shall contain no
  ///   configuration information.
  /// - If a single Type with value 'All' is provided the returned profiles
  ///   shall include all associated configurations.
  /// - Otherwise the requested list of configurations shall for each profile
  ///   include the configurations present as Type.
  ///
  /// [referenceToken] - optional;
  /// Optional token of the requested profile.
  /// [type] - optional, unbounded; List\<String>
  /// The types shall be provided as defined by tr2:ConfigurationEnumeration.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<List<MediaProfile>> getProfiles({
    String? referenceToken,
    List<String>? type,
  }) async {
    loggy.debug('getProfiles');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: Media2Request.getProfiles()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetProfilesResponse.fromJson(
      responseEnvelope.body.response!,
    ).profiles;
  }

  /// Returns the capabilities of the media service. The result is returned in a
  /// typed answer.
  ///
  /// ACCESS CLASS: PRE_AUTH
  Future<Capabilities2> getServiceCapabilities() async {
    loggy.debug('getServiceCapabilities');

    final responseEnvelope = await transport.request(
      uri,
      soap.Body(request: Media2Request.getServiceCapabilities()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetServiceCapabilitiesResponse.fromJson(
      responseEnvelope.body.response!,
    ).capabilities;
  }

  /// A client uses the [getSnapshotUri] command to obtain a JPEG snapshot from
  /// the device. The returned URI shall remain valid indefinitely even if the
  /// profile is changed. The [validUntilConnect], [validUntilReboot] and
  /// [timeout] parameter shall be set accordingly (validUntilConnect=false,
  /// validUntilReboot=false, timeout=PT0S). The URI can be used for
  /// acquiring a JPEG image through a HTTP GET operation. The image encoding
  /// will always be JPEG regardless of the encoding setting in the media
  /// profile. The Jpeg settings (like resolution or quality) may be taken from
  /// the profile if suitable. The provided image will be updated automatically
  /// and independent from calls to [getSnapshotUri].
  ///
  /// [profileToken] - the ProfileToken element indicates the media profile to
  /// use and will define the source and dimensions of the snapshot.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<String> getSnapshotUri(String profileToken) async {
    loggy.debug('getSnapshotUri');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: Media2Request.getSnapshotUri(profileToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetSnapshotUriResponse.fromJson(responseEnvelope.body.response!).uri;
  }

  /// This operation requests a [Uri] that can be used to initiate a live media
  /// stream using RTSP as the control protocol. The returned URI shall remain
  /// valid indefinitely even if the profile is changed. The
  /// [validUntilConnect], [validUntilReboot] and Timeout Parameter shall be set
  /// accordingly (validUntilConnect=false, validUntilReboot=false,
  /// timeout=PT0S).
  ///
  /// The correct syntax for the StreamSetup element for these media stream
  /// setups defined in 5.1.1 of the streaming specification are as follows:
  ///  RTP unicast over UDP: StreamType = "RTP-Unicast", TransportProtocol =
  /// "UDP"   ///  RTP over RTSP over HTTP over TCP: StreamType = "RTP-Unicast",
  /// TransportProtocol = "HTTP"   ///  RTP over RTSP over TCP: StreamType =
  /// "RTP-Unicast", TransportProtocol = "RTSP"
  ///
  /// If a multicast stream is requested at least one of
  /// videoEncoderConfiguration, audioEncoderConfiguration and
  /// metadataConfiguration shall have a valid multicast setting.
  ///
  /// For full compatibility with other ONVIF services a device should not
  /// generate Uris longer than 128 octets.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<String> getStreamUri(
    String profileToken, {
    String streamType = 'RTP-Multicast',
    String protocol = 'RTSP',
  }) async {
    loggy.debug('getStreamUri');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: Media2Request.getStreamUri(profileToken, protocol: protocol),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetStreamUriResponse.fromJson(responseEnvelope.body.response!).uri;
  }

  /// By default this operation lists all existing video encoder configurations
  /// for a device. Provide a profile token to list only configurations that are
  /// compatible with the profile. If a configuration token is provided only a
  /// single configuration will be returned.
  Future<List<VideoEncoder2Configuration>> getVideoEncoderConfigurations({
    String? configurationToken,
    String? profileToken,
  }) async {
    loggy.debug('getVideoEncoderConfigurations');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: Media2Request.videoEncoderConfigurations(
          configurationToken: configurationToken,
          profileToken: profileToken,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetVideoEncoderConfigurationsResponse.fromJson(
      responseEnvelope.body.response!,
    ).configurations;
  }

  /// The GetVideoEncoderInstances command can be used to request the minimum
  /// number of guaranteed video encoder instances (applications) per Video
  /// Source Configuration.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<Info> getVideoEncoderInstances(String configurationToken) async {
    loggy.debug('getVideoEncoderInstances');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: Media2Request.getVideoEncoderInstances(configurationToken),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetVideoEncoderInstancesResponse.fromJson(
      responseEnvelope.body.response!,
    ).info;
  }

  /// This operation returns the available options (supported values and ranges
  /// for video source configuration parameters) when the video source
  /// parameters are reconfigured If a video source configuration is specified,
  /// the options shall concern that particular configuration. If a media
  /// profile is specified, the options shall be compatible with that media
  /// profile.
  ///
  /// ACCESS CLASS: READ_SYSTEM
  Future<VideoSourceConfigurationOptions> getVideoSourceConfigurationOptions({
    String? configurationToken,
    String? profileToken,
  }) async {
    loggy.debug('getVideoSourceConfigurationOptionsResponse');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: Media2Request.getVideoSourceConfigurationOptions(
          configurationToken: configurationToken,
          profileToken: profileToken,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetVideoSourceConfigurationOptionsResponse.fromJson(
      responseEnvelope.body.response!,
    ).options;
  }

  /// This command starts multicast streaming using a specified media profile of
  /// a device. Streaming continues until StopMulticastStreaming is called for
  /// the same Profile. The streaming shall continue after a reboot of the
  /// device until a StopMulticastStreaming request is received. The multicast
  /// address, port and TTL are configured in the VideoEncoderConfiguration,
  /// AudioEncoderConfiguration and MetadataConfiguration respectively.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> startMulticastStreaming(String profileToken) async {
    loggy.debug('startMulticastStreaming');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: Media2Request.startMulticastStreaming(profileToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }

  /// This command stop multicast streaming using a specified media profile of a
  /// device
  ///
  /// [profileToken] - contains the token of the Profile that is used to define
  /// the multicast stream.
  ///
  /// ACCESS CLASS: ACTUATE
  Future<bool> stopMulticastStreaming(String profileToken) async {
    loggy.debug('stopMulticastStreaming');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: Media2Request.stopMulticastStreaming(profileToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }
    return true;
  }

  /// This operation returns the configured WebRTC signaling configurations of a
  /// device.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<List<WebrtcConfiguration>> getWebRTCConfigurations() async {
    loggy.debug('getWebRTCConfigurations');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: Media2Request.getWebRTCConfigurations()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetWebrtcConfigurationsResponse.fromJson(
      responseEnvelope.body.response!,
    ).configurations;
  }

  /// This operation configures the WebRTC signaling configurations of a device.
  /// Passing an empty list deletes the existing configurations.
  ///
  /// ACCESS CLASS: WRITE_SYSTEM
  Future<bool> setWebRTCConfigurations(
    List<WebrtcConfiguration> configurations,
  ) async {
    loggy.debug('setWebRTCConfigurations');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: Media2Request.setWebRTCConfigurations(configurations),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }
}
