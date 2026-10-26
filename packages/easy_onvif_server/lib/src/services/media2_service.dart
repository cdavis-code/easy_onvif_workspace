import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../config.dart';
import '../hardware/device_state.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import '../streaming/stream_backend.dart';
import '../webrtc/webrtc_service.dart';
import 'onvif_service.dart';

/// Implements the ONVIF Media2 service (`tr2` namespace, ver20).
///
/// When a device advertises both Media1 and Media2 the `easy_onvif` client's
/// `Media` facade routes `getProfiles`, `getStreamUri` and `getSnapshotUri`
/// here, making this the primary media service.
class Media2Service implements OnvifService {
  final ServerConfig config;
  final DeviceState state;
  final StreamBackend streamBackend;

  /// The WebRTC signaling service, used to report the read-only `Connected`
  /// state in `GetWebRTCConfigurations`. Optional so the service works when
  /// WebRTC is not wired up.
  final WebrtcService? webrtcService;

  /// In-memory WebRTC configuration state surfaced by
  /// `Get/SetWebRTCConfigurations`. The server reflects its own built-in
  /// `/onvif/webrtc` signaling endpoint rather than connecting to an external
  /// signaling server.
  bool _webRtcEnabled = true;
  String? _webRtcDefaultProfile;

  Media2Service({
    required this.config,
    required this.state,
    required this.streamBackend,
    this.webrtcService,
  });

  String get _webRtcDefaultProfileToken =>
      _webRtcDefaultProfile ?? DeviceState.profileToken;

  @override
  bool handles(String namespace) => namespace == Xmlns.tr2;

  @override
  bool isPreAuth(String operation) => operation == 'GetServiceCapabilities';

  @override
  Future<String> handle(RequestContext ctx, {required String host}) async {
    switch (ctx.operation) {
      case 'GetProfiles':
        return _getProfiles();
      case 'GetStreamUri':
        return _getStreamUri(ctx, host);
      case 'GetSnapshotUri':
        return _getSnapshotUri(ctx, host);
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      case 'GetMetadataConfigurations':
        return _empty('GetMetadataConfigurationsResponse');
      case 'GetVideoEncoderConfigurations':
        return _getVideoEncoderConfigurations();
      case 'GetVideoEncoderInstances':
        return _getVideoEncoderInstances();
      case 'GetVideoSourceConfigurationOptions':
        return _getVideoSourceConfigurationOptions();
      case 'GetMetadataConfigurationOptions':
        return _getMetadataConfigurationOptions();
      case 'StartMulticastStreaming':
        return _empty('StartMulticastStreamingResponse');
      case 'StopMulticastStreaming':
        return _empty('StopMulticastStreamingResponse');
      case 'GetWebRTCConfigurations':
        return _getWebRTCConfigurations(host);
      case 'SetWebRTCConfigurations':
        return _setWebRTCConfigurations(ctx);
      default:
        return SoapEnvelopeBuilder.fault(
          subcode: 'ActionNotSupported',
          reason: 'The requested action is not supported by this device.',
        );
    }
  }

  String _getProfiles() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetProfilesResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          for (final profile in state.profiles) {
            b.element(
              'Profiles',
              namespaceUri: Xmlns.tr2,
              attributes: {'token': profile.token, 'fixed': 'true'},
              nest: () {
                b.element('Name', namespaceUri: Xmlns.tr2, nest: profile.name);
              },
            );
          }
        },
      );
    });
  }

  Future<String> _getStreamUri(RequestContext ctx, String host) async {
    final profileToken = ctx.param('ProfileToken') ?? DeviceState.profileToken;

    final uri = await streamBackend.start(profileToken, host: host);

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetStreamUriResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          b.element('Uri', namespaceUri: Xmlns.tr2, nest: uri);
        },
      );
    });
  }

  String _getSnapshotUri(RequestContext ctx, String host) {
    final profileToken = ctx.param('ProfileToken') ?? DeviceState.profileToken;

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetSnapshotUriResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          b.element(
            'Uri',
            namespaceUri: Xmlns.tr2,
            nest: config.snapshotUrl(host, profileToken),
          );
        },
      );
    });
  }

  String _getServiceCapabilities() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetServiceCapabilitiesResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          b.element(
            'Capabilities',
            namespaceUri: Xmlns.tr2,
            attributes: {
              'SnapshotUri': 'true',
              'Rotation': 'false',
              'VideoSourceMode': 'false',
              'OSD': 'false',
              'Mask': 'false',
            },
            nest: () {
              b.element(
                'ProfileCapabilities',
                namespaceUri: Xmlns.tr2,
                attributes: {'MaximumNumberOfProfiles': '10'},
              );
              b.element(
                'StreamingCapabilities',
                namespaceUri: Xmlns.tr2,
                attributes: {
                  'RTSPStreaming': 'true',
                  'RTPMulticast': 'true',
                  'RTP_RTSP_TCP': 'true',
                  'NonAggregateControl': 'false',
                },
              );
            },
          );
        },
      );
    });
  }

  /// Describes the encoder used for the live stream; the resolution and frame
  /// rate constants match the actual encoded stream (1280×720 @ 15 fps, see
  /// `_platformVideoInput` in the ffmpeg backend).
  String _getVideoEncoderConfigurations() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetVideoEncoderConfigurationsResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          b.element(
            'Configurations',
            namespaceUri: Xmlns.tr2,
            attributes: {
              'token': 'VideoEncoderConfig_1',
              'GovLength': '15',
              'Profile': 'Main',
            },
            nest: () {
              b.element('Name', namespaceUri: Xmlns.tt, nest: 'VideoEncoder_1');
              b.element('UseCount', namespaceUri: Xmlns.tt, nest: '1');
              b.element('Encoding', namespaceUri: Xmlns.tt, nest: 'H264');
              b.element(
                'Resolution',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element('Width', namespaceUri: Xmlns.tt, nest: '1280');
                  b.element('Height', namespaceUri: Xmlns.tt, nest: '720');
                },
              );
              b.element(
                'RateControl',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element('FrameRateLimit', namespaceUri: Xmlns.tt, nest: '15');
                  b.element('BitrateLimit', namespaceUri: Xmlns.tt, nest: '2048');
                },
              );
              b.element('Quality', namespaceUri: Xmlns.tt, nest: '5.0');
            },
          );
        },
      );
    });
  }

  String _getVideoEncoderInstances() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetVideoEncoderInstancesResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          b.element(
            'Info',
            namespaceUri: Xmlns.tr2,
            nest: () {
              b.element('Total', namespaceUri: Xmlns.tr2, nest: '1');
            },
          );
        },
      );
    });
  }

  /// The device does not support cropped streaming, so the bounds ranges pin
  /// the capture area to the full video source dimensions.
  String _getVideoSourceConfigurationOptions() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetVideoSourceConfigurationOptionsResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          b.element(
            'Options',
            namespaceUri: Xmlns.tr2,
            nest: () {
              b.element(
                'BoundsRange',
                namespaceUri: Xmlns.tt,
                nest: () {
                  _writeIntRange(b, 'XRange', 0, 0);
                  _writeIntRange(b, 'YRange', 0, 0);
                  _writeIntRange(b, 'WidthRange', 1280, 1280);
                  _writeIntRange(b, 'HeightRange', 720, 720);
                },
              );
              b.element(
                'VideoSourceTokensAvailable',
                namespaceUri: Xmlns.tt,
                nest: DeviceState.videoSourceToken,
              );
            },
          );
        },
      );
    });
  }

  String _getMetadataConfigurationOptions() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetMetadataConfigurationOptionsResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          b.element(
            'Options',
            namespaceUri: Xmlns.tr2,
            nest: () {
              b.element(
                'PTZStatusFilterOptions',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element(
                    'PanTiltStatusSupported',
                    namespaceUri: Xmlns.tt,
                    nest: 'false',
                  );
                  b.element(
                    'ZoomStatusSupported',
                    namespaceUri: Xmlns.tt,
                    nest: 'false',
                  );
                },
              );
            },
          );
        },
      );
    });
  }

  void _writeIntRange(XmlBuilder b, String name, int min, int max) {
    b.element(
      name,
      namespaceUri: Xmlns.tt,
      nest: () {
        b.element('Min', namespaceUri: Xmlns.tt, nest: '$min');
        b.element('Max', namespaceUri: Xmlns.tt, nest: '$max');
      },
    );
  }

  /// Returns a single WebRTC configuration describing this device's built-in
  /// `/onvif/webrtc` signaling endpoint. The `AuthorizationServer` is a
  /// placeholder (OAuth2 / the Security Service spec is out of scope), and
  /// `Connected` reflects whether a signaling session is currently active.
  String _getWebRTCConfigurations(String host) {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetWebRTCConfigurationsResponse',
        namespaceUri: Xmlns.tr2,
        nest: () {
          b.element(
            'WebRTCConfiguration',
            namespaceUri: Xmlns.tr2,
            nest: () {
              b.element(
                'SignalingServer',
                namespaceUri: Xmlns.tr2,
                nest: 'ws://$host:${config.httpPort}/onvif/webrtc',
              );
              b.element(
                'AuthorizationServer',
                namespaceUri: Xmlns.tr2,
                nest: 'AuthorizationServer_1',
              );
              b.element(
                'DefaultProfile',
                namespaceUri: Xmlns.tr2,
                nest: _webRtcDefaultProfileToken,
              );
              b.element(
                'Enabled',
                namespaceUri: Xmlns.tr2,
                nest: '$_webRtcEnabled',
              );
              b.element(
                'Connected',
                namespaceUri: Xmlns.tr2,
                nest: '${webrtcService?.hasActiveSession ?? false}',
              );
            },
          );
        },
      );
    });
  }

  /// Stores the mutable fields (`Enabled`, `DefaultProfile`) of the provided
  /// configuration in memory. The server reflects its own built-in signaling
  /// endpoint, so `SignalingServer`/`AuthorizationServer` are acknowledged but
  /// never acted upon (no external connection is made). An empty set resets to
  /// defaults.
  String _setWebRTCConfigurations(RequestContext ctx) {
    final configurations = ctx.params('WebRTCConfiguration');

    if (configurations.isEmpty) {
      _webRtcEnabled = true;
      _webRtcDefaultProfile = null;
    } else {
      // The device reflects a single built-in signaling endpoint, so it holds
      // exactly one configuration.
      if (configurations.length > 1) {
        return SoapEnvelopeBuilder.fault(
          subcode: 'InvalidArgVal',
          reason: 'This device supports a single WebRTC configuration.',
        );
      }

      final configuration = configurations.first;

      final enabled = _childText(configuration, 'Enabled');
      if (enabled != null) _webRtcEnabled = enabled.toLowerCase() == 'true';

      final defaultProfile = _childText(configuration, 'DefaultProfile');
      if (defaultProfile != null) {
        if (!state.profiles.any((profile) => profile.token == defaultProfile)) {
          return SoapEnvelopeBuilder.fault(
            subcode: 'InvalidArgVal',
            reason: 'Unknown DefaultProfile token: $defaultProfile',
          );
        }
        _webRtcDefaultProfile = defaultProfile;
      }
    }

    return _empty('SetWebRTCConfigurationsResponse');
  }

  /// The trimmed text of the first direct child of [element] named
  /// [localName], or `null` if absent or empty.
  String? _childText(XmlElement element, String localName) {
    for (final child in element.childElements) {
      if (child.localName == localName) {
        final text = child.innerText.trim();

        return text.isEmpty ? null : text;
      }
    }

    return null;
  }

  String _empty(String responseName) {
    return SoapEnvelopeBuilder.response((b) {
      b.element(responseName, namespaceUri: Xmlns.tr2, nest: () {});
    });
  }
}
