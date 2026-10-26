import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../config.dart';
import '../recording/recording_manager.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import 'onvif_service.dart';

/// Implements the ONVIF Replay service (`trp` namespace).
///
/// Replay URIs point at the embedded RTSP server's `/onvif/replay/<token>`
/// path, which serves the recording's real `.h264` segments from disk.
class ReplayService implements OnvifService {
  final ServerConfig config;
  final RecordingManager manager;

  /// The RTSP session timeout reported (and accepted) by the configuration
  /// operations.
  String _sessionTimeout = 'PT60S';

  ReplayService({required this.config, required this.manager});

  @override
  bool handles(String namespace) => namespace == Xmlns.trp;

  @override
  bool isPreAuth(String operation) => operation == 'GetServiceCapabilities';

  @override
  Future<String> handle(RequestContext ctx, {required String host}) async {
    switch (ctx.operation) {
      case 'GetReplayUri':
        return _getReplayUri(ctx, host);
      case 'GetReplayConfiguration':
        return _getReplayConfiguration();
      case 'SetReplayConfiguration':
        return _setReplayConfiguration(ctx);
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      default:
        return SoapEnvelopeBuilder.fault(
          subcode: 'ActionNotSupported',
          reason: 'The requested action is not supported by this device.',
        );
    }
  }

  String _getReplayUri(RequestContext ctx, String host) {
    final token = ctx.param('RecordingToken');

    if (token == null || manager.recording(token) == null) {
      return SoapEnvelopeBuilder.fault(
        subcode: 'NoRecording',
        reason: 'No recording exists for token "$token".',
      );
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetReplayUriResponse',
        namespaceUri: Xmlns.trp,
        nest: () {
          b.element(
            'Uri',
            namespaceUri: Xmlns.trp,
            nest: config.replayRtspUrl(host, token),
          );
        },
      );
    });
  }

  String _getReplayConfiguration() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetReplayConfigurationResponse',
        namespaceUri: Xmlns.trp,
        nest: () {
          b.element(
            'Configuration',
            namespaceUri: Xmlns.trp,
            nest: () {
              b.element(
                'SessionTimeout',
                namespaceUri: Xmlns.tt,
                nest: _sessionTimeout,
              );
            },
          );
        },
      );
    });
  }

  String _setReplayConfiguration(RequestContext ctx) {
    final configuration = ctx.params('Configuration').firstOrNull;
    final timeout = configuration?.childElements
        .where((child) => child.localName == 'SessionTimeout')
        .firstOrNull
        ?.innerText
        .trim();

    if (timeout != null && timeout.isNotEmpty) _sessionTimeout = timeout;

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'SetReplayConfigurationResponse',
        namespaceUri: Xmlns.trp,
        nest: () {},
      );
    });
  }

  String _getServiceCapabilities() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetServiceCapabilitiesResponse',
        namespaceUri: Xmlns.trp,
        nest: () {
          b.element(
            'Capabilities',
            namespaceUri: Xmlns.trp,
            attributes: {
              'ReversePlayback': 'false',
              'SessionTimeoutRange': '10 120',
              'RTP_RTSP_TCP': 'true',
              'RTSPWebSocketUri': '',
            },
          );
        },
      );
    });
  }
}
