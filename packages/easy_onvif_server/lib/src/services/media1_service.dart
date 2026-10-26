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

  /// Whether audio streaming is enabled; when false the audio configuration
  /// operations return empty lists.
  final bool audioEnabled;

  Media1Service({
    required this.config,
    required this.state,
    required this.streamBackend,
    this.audioEnabled = false,
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
      case 'GetAudioSourceConfigurations':
        return _getAudioSourceConfigurations();
      case 'GetAudioEncoderConfigurations':
        return _getAudioEncoderConfigurations();
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      case 'GetMetadataConfigurations':
        return _empty('GetMetadataConfigurationsResponse');
      case 'GetMetadataConfiguration':
        return _getMetadataConfiguration(ctx);
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
        namespaceUri: Xmlns.trt,
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
        namespaceUri: Xmlns.trt,
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
        namespaceUri: Xmlns.trt,
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
        namespaceUri: Xmlns.trt,
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
        namespaceUri: Xmlns.trt,
        nest: () {
          b.element(
            'VideoSources',
            namespaceUri: Xmlns.trt,
            attributes: {'token': DeviceState.videoSourceToken},
            nest: () {
              b.element('Framerate', namespaceUri: Xmlns.tt, nest: '30');
              b.element(
                'Resolution',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element('Width', namespaceUri: Xmlns.tt, nest: '1920');
                  b.element('Height', namespaceUri: Xmlns.tt, nest: '1080');
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
        namespaceUri: Xmlns.trt,
        nest: () {
          b.element(
            'AudioSources',
            namespaceUri: Xmlns.trt,
            attributes: {'token': 'AudioSource_1'},
            nest: () {
              b.element('Channels', namespaceUri: Xmlns.tt, nest: '1');
            },
          );
        },
      );
    });
  }

  String _getAudioSourceConfigurations() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetAudioSourceConfigurationsResponse',
        namespaceUri: Xmlns.trt,
        nest: () {
          if (!audioEnabled) return;

          b.element(
            'Configurations',
            namespaceUri: Xmlns.trt,
            attributes: {'token': 'AudioSourceConfig_1'},
            nest: () {
              b.element(
                'Name',
                namespaceUri: Xmlns.tt,
                nest: 'Audio Source Config',
              );
              b.element('UseCount', namespaceUri: Xmlns.tt, nest: '1');
              b.element(
                'SourceToken',
                namespaceUri: Xmlns.tt,
                nest: 'AudioSource_1',
              );
            },
          );
        },
      );
    });
  }

  String _getAudioEncoderConfigurations() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetAudioEncoderConfigurationsResponse',
        namespaceUri: Xmlns.trt,
        nest: () {
          if (!audioEnabled) return;

          b.element(
            'Configurations',
            namespaceUri: Xmlns.trt,
            attributes: {'token': 'AudioEncoderConfig_1'},
            nest: () {
              b.element('Name', namespaceUri: Xmlns.tt, nest: 'G711 Encoder');
              b.element('UseCount', namespaceUri: Xmlns.tt, nest: '1');
              b.element('Encoding', namespaceUri: Xmlns.tt, nest: 'G711');
              b.element('Bitrate', namespaceUri: Xmlns.tt, nest: '64');
              b.element('SampleRate', namespaceUri: Xmlns.tt, nest: '8');
              // Multicast and SessionTimeout are required (minOccurs=1) in
              // the tt:AudioEncoderConfiguration schema.
              b.element(
                'Multicast',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element(
                    'Address',
                    namespaceUri: Xmlns.tt,
                    nest: () {
                      b.element('Type', namespaceUri: Xmlns.tt, nest: 'IPv4');
                      b.element(
                        'IPv4Address',
                        namespaceUri: Xmlns.tt,
                        nest: '0.0.0.0',
                      );
                    },
                  );
                  b.element('Port', namespaceUri: Xmlns.tt, nest: '0');
                  b.element('TTL', namespaceUri: Xmlns.tt, nest: '0');
                  b.element('AutoStart', namespaceUri: Xmlns.tt, nest: 'false');
                },
              );
              b.element('SessionTimeout', namespaceUri: Xmlns.tt, nest: 'PT60S');
            },
          );
        },
      );
    });
  }

  /// The token of the single (simulated) metadata configuration.
  static const _metadataConfigToken = 'MetadataConfig_1';

  String _getMetadataConfiguration(RequestContext ctx) {
    final token = ctx.param('ConfigurationToken');

    if (token != null && token != _metadataConfigToken) {
      return SoapEnvelopeBuilder.fault(
        subcode: 'NoConfig',
        reason: 'No metadata configuration exists for token "$token".',
      );
    }

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetMetadataConfigurationResponse',
        namespaceUri: Xmlns.trt,
        nest: () {
          b.element(
            'Configuration',
            namespaceUri: Xmlns.trt,
            attributes: {'token': _metadataConfigToken},
            nest: () {
              b.element('Name', namespaceUri: Xmlns.tt, nest: 'Metadata 1');
              b.element('UseCount', namespaceUri: Xmlns.tt, nest: '1');
              b.element('SessionTimeout', namespaceUri: Xmlns.tt, nest: 'PT60S');
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
        namespaceUri: Xmlns.trt,
        nest: () {
          b.element(
            'Capabilities',
            namespaceUri: Xmlns.trt,
            attributes: {
              'SnapshotUri': 'true',
              'Rotation': 'false',
              'VideoSourceMode': 'false',
              'OSD': 'false',
            },
            nest: () {
              b.element(
                'ProfileCapabilities',
                namespaceUri: Xmlns.trt,
                attributes: {'MaximumNumberOfProfiles': '10'},
              );
              b.element(
                'StreamingCapabilities',
                namespaceUri: Xmlns.trt,
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
      namespaceUri: Xmlns.trt,
      attributes: {'token': token, 'fixed': 'true'},
      nest: () {
        b.element('Name', namespaceUri: Xmlns.tt, nest: name);
      },
    );
  }

  void _writeMediaUri(XmlBuilder b, String uri) {
    b.element(
      'MediaUri',
      namespaceUri: Xmlns.trt,
      nest: () {
        b.element('Uri', namespaceUri: Xmlns.tt, nest: uri);
        b.element('InvalidAfterConnect', namespaceUri: Xmlns.tt, nest: 'false');
        b.element('InvalidAfterReboot', namespaceUri: Xmlns.tt, nest: 'false');
        b.element('Timeout', namespaceUri: Xmlns.tt, nest: 'PT60S');
      },
    );
  }

  String _empty(String responseName) {
    return SoapEnvelopeBuilder.response((b) {
      b.element(responseName, namespaceUri: Xmlns.trt, nest: () {});
    });
  }
}
