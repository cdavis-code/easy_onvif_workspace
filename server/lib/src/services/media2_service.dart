import 'package:easy_onvif/soap.dart' show Xmlns;

import '../config.dart';
import '../hardware/device_state.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import '../streaming/stream_backend.dart';
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

  Media2Service({
    required this.config,
    required this.state,
    required this.streamBackend,
  });

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
        namespace: Xmlns.tr2,
        nest: () {
          for (final profile in state.profiles) {
            b.element(
              'Profiles',
              namespace: Xmlns.tr2,
              attributes: {'token': profile.token, 'fixed': 'true'},
              nest: () {
                b.element('Name', namespace: Xmlns.tr2, nest: profile.name);
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
        namespace: Xmlns.tr2,
        nest: () {
          b.element('Uri', namespace: Xmlns.tr2, nest: uri);
        },
      );
    });
  }

  String _getSnapshotUri(RequestContext ctx, String host) {
    final profileToken = ctx.param('ProfileToken') ?? DeviceState.profileToken;

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetSnapshotUriResponse',
        namespace: Xmlns.tr2,
        nest: () {
          b.element(
            'Uri',
            namespace: Xmlns.tr2,
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
        namespace: Xmlns.tr2,
        nest: () {
          b.element(
            'Capabilities',
            namespace: Xmlns.tr2,
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
                namespace: Xmlns.tr2,
                attributes: {'MaximumNumberOfProfiles': '10'},
              );
              b.element(
                'StreamingCapabilities',
                namespace: Xmlns.tr2,
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

  String _empty(String responseName) {
    return SoapEnvelopeBuilder.response((b) {
      b.element(responseName, namespace: Xmlns.tr2, nest: () {});
    });
  }
}
