import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../config.dart';
import '../hardware/device_state.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import '../streaming/stream_backend.dart';
import 'onvif_service.dart';

/// Implements the ONVIF Media1 service (`trt` namespace, ver10).
///
/// Used by the client when only Media1 is advertised; when both Media1 and
/// Media2 are present the `Media` facade prefers Media2 for the common calls,
/// but Media1-only operations (e.g. `GetVideoSources`) still route here.
class Media1Service implements OnvifService {
  final ServerConfig config;
  final DeviceState state;
  final StreamBackend streamBackend;

  Media1Service({
    required this.config,
    required this.state,
    required this.streamBackend,
  });

  @override
  bool handles(String namespace) => namespace == Xmlns.trt;

  @override
  bool isPreAuth(String operation) => operation == 'GetServiceCapabilities';

  @override
  Future<String> handle(RequestContext ctx, {required String host}) async {
    switch (ctx.operation) {
      case 'GetProfiles':
        return _getProfiles();
      case 'GetProfile':
        return _getProfile(ctx);
      case 'GetStreamUri':
        return _getStreamUri(ctx, host);
      case 'GetSnapshotUri':
        return _getSnapshotUri(ctx, host);
      case 'GetVideoSources':
        return _getVideoSources();
      case 'GetAudioSources':
        return _getAudioSources();
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      case 'GetMetadataConfigurations':
        return _empty('GetMetadataConfigurationsResponse');
      case 'StartMulticastStreaming':
        return _empty('StartMulticastStreamingResponse');
      case 'StopMulticastStreaming':
        return _empty('StopMulticastStreamingResponse');
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
        namespace: Xmlns.trt,
        nest: () {
          for (final profile in state.profiles) {
            _writeProfile(b, profile.token, profile.name);
          }
        },
      );
    });
  }

  String _getProfile(RequestContext ctx) {
    final token = ctx.param('ProfileToken') ?? DeviceState.profileToken;
    final profile = state.profiles.firstWhere(
      (p) => p.token == token,
      orElse: () => state.profiles.first,
    );

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetProfileResponse',
        namespace: Xmlns.trt,
        nest: () {
          _writeProfile(b, profile.token, profile.name);
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
        namespace: Xmlns.trt,
        nest: () {
          _writeMediaUri(b, uri);
        },
      );
    });
  }

  String _getSnapshotUri(RequestContext ctx, String host) {
    final profileToken = ctx.param('ProfileToken') ?? DeviceState.profileToken;

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetSnapshotUriResponse',
        namespace: Xmlns.trt,
        nest: () {
          _writeMediaUri(b, config.snapshotUrl(host, profileToken));
        },
      );
    });
  }

  String _getVideoSources() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetVideoSourcesResponse',
        namespace: Xmlns.trt,
        nest: () {
          b.element(
            'VideoSources',
            namespace: Xmlns.trt,
            attributes: {'token': DeviceState.videoSourceToken},
            nest: () {
              b.element('Framerate', namespace: Xmlns.tt, nest: '30');
              b.element(
                'Resolution',
                namespace: Xmlns.tt,
                nest: () {
                  b.element('Width', namespace: Xmlns.tt, nest: '1920');
                  b.element('Height', namespace: Xmlns.tt, nest: '1080');
                },
              );
            },
          );
        },
      );
    });
  }

  String _getAudioSources() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetAudioSourcesResponse',
        namespace: Xmlns.trt,
        nest: () {
          b.element(
            'AudioSources',
            namespace: Xmlns.trt,
            attributes: {'token': 'AudioSource_1'},
            nest: () {
              b.element('Channels', namespace: Xmlns.tt, nest: '1');
            },
          );
        },
      );
    });
  }

  String _getServiceCapabilities() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetServiceCapabilitiesResponse',
        namespace: Xmlns.trt,
        nest: () {
          b.element(
            'Capabilities',
            namespace: Xmlns.trt,
            attributes: {
              'SnapshotUri': 'true',
              'Rotation': 'false',
              'VideoSourceMode': 'false',
              'OSD': 'false',
            },
            nest: () {
              b.element(
                'ProfileCapabilities',
                namespace: Xmlns.trt,
                attributes: {'MaximumNumberOfProfiles': '10'},
              );
              b.element(
                'StreamingCapabilities',
                namespace: Xmlns.trt,
                attributes: {
                  'RTPMulticast': 'true',
                  'RTP_TCP': 'true',
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _writeProfile(XmlBuilder b, String token, String name) {
    b.element(
      'Profiles',
      namespace: Xmlns.trt,
      attributes: {'token': token, 'fixed': 'true'},
      nest: () {
        b.element('Name', namespace: Xmlns.tt, nest: name);
      },
    );
  }

  void _writeMediaUri(XmlBuilder b, String uri) {
    b.element(
      'MediaUri',
      namespace: Xmlns.trt,
      nest: () {
        b.element('Uri', namespace: Xmlns.tt, nest: uri);
        b.element('InvalidAfterConnect', namespace: Xmlns.tt, nest: 'false');
        b.element('InvalidAfterReboot', namespace: Xmlns.tt, nest: 'false');
        b.element('Timeout', namespace: Xmlns.tt, nest: 'PT60S');
      },
    );
  }

  String _empty(String responseName) {
    return SoapEnvelopeBuilder.response((b) {
      b.element(responseName, namespace: Xmlns.trt, nest: () {});
    });
  }
}
