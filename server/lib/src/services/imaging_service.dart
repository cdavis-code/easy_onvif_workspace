import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../hardware/device_state.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import 'onvif_service.dart';

/// Implements the ONVIF Imaging service (`timg` namespace).
///
/// Presets are simulated: they are seeded from settings and applying one only
/// updates [DeviceState.currentImagingPreset]. The client's `ImagingPreset`
/// model parses `@token` plus lowercase `type`/`name` child elements, and
/// `GetPresetsResponse` casts `Preset` to a `List`, so at least two presets
/// must always be advertised.
class ImagingService implements OnvifService {
  final DeviceState state;

  ImagingService({required this.state});

  @override
  bool handles(String namespace) => namespace == Xmlns.timg;

  @override
  bool isPreAuth(String operation) => operation == 'GetServiceCapabilities';

  @override
  Future<String> handle(RequestContext ctx, {required String host}) async {
    switch (ctx.operation) {
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      case 'GetPresets':
        return _checkSource(ctx) ?? _getPresets();
      case 'GetCurrentPreset':
        return _checkSource(ctx) ?? _getCurrentPreset();
      case 'SetCurrentPreset':
      // The `easy_onvif` client's `setCurrentPreset` builds a `SetPreset`
      // element (upstream bug); accept it as an alias for interop.
      case 'SetPreset':
        return _checkSource(ctx) ?? _setCurrentPreset(ctx);
      case 'GetStatus':
        return _checkSource(ctx) ?? _getStatus();
      default:
        return SoapEnvelopeBuilder.fault(
          subcode: 'ActionNotSupported',
          reason: 'The requested action is not supported by this device.',
        );
    }
  }

  /// Returns a `NoSource` fault when the request addresses an unknown video
  /// source, or null when the token matches the device's single source.
  String? _checkSource(RequestContext ctx) {
    final token = ctx.param('VideoSourceToken');

    if (token == DeviceState.videoSourceToken) return null;

    return SoapEnvelopeBuilder.fault(
      subcode: 'NoSource',
      reason: 'No video source exists for token "$token".',
    );
  }

  String _getServiceCapabilities() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetServiceCapabilitiesResponse',
        namespaceUri: Xmlns.timg,
        nest: () {
          b.element(
            'Capabilities',
            namespaceUri: Xmlns.timg,
            attributes: {
              'ImageStabilization': 'false',
              'Presets': 'true',
              'AdaptablePreset': 'false',
            },
          );
        },
      );
    });
  }

  void _writePreset(XmlBuilder b, ImagingPreset preset) {
    b.element(
      'Preset',
      namespaceUri: Xmlns.timg,
      attributes: {'token': preset.token, 'type': preset.type},
      nest: () {
        // The client model expects lowercase `type`/`name` child elements.
        b.element('type', namespaceUri: Xmlns.timg, nest: preset.type);
        b.element('name', namespaceUri: Xmlns.timg, nest: preset.name);
      },
    );
  }

  String _getPresets() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetPresetsResponse',
        namespaceUri: Xmlns.timg,
        nest: () {
          for (final preset in state.imagingPresets) {
            _writePreset(b, preset);
          }
        },
      );
    });
  }

  String _getCurrentPreset() {
    final current = state.imagingPresets
        .where((preset) => preset.token == state.currentImagingPreset)
        .firstOrNull;

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetCurrentPresetResponse',
        namespaceUri: Xmlns.timg,
        nest: () {
          if (current != null) _writePreset(b, current);
        },
      );
    });
  }

  String _setCurrentPreset(RequestContext ctx) {
    final presetToken = ctx.param('PresetToken');
    final known = state.imagingPresets.any(
      (preset) => preset.token == presetToken,
    );

    if (presetToken == null || !known) {
      return SoapEnvelopeBuilder.fault(
        subcode: 'NoConfig',
        reason: 'No imaging preset exists for token "$presetToken".',
      );
    }

    state.currentImagingPreset = presetToken;

    return SoapEnvelopeBuilder.response((b) {
      b.element('SetCurrentPresetResponse', namespaceUri: Xmlns.timg, nest: () {});
    });
  }

  String _getStatus() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetStatusResponse',
        namespaceUri: Xmlns.timg,
        nest: () {
          b.element(
            'Status',
            namespaceUri: Xmlns.timg,
            nest: () {
              b.element(
                'FocusStatus20',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element('Position', namespaceUri: Xmlns.tt, nest: '0.5');
                  b.element('MoveStatus', namespaceUri: Xmlns.tt, nest: 'IDLE');
                },
              );
            },
          );
        },
      );
    });
  }
}
