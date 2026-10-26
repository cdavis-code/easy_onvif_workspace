import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import '../hardware/device_state.dart';
import '../soap/envelope_builder.dart';
import '../soap/request_context.dart';
import 'onvif_service.dart';

/// Implements the ONVIF PTZ service (`tptz` namespace).
///
/// PTZ state is simulated in [DeviceState]: continuous moves run on a timer,
/// absolute/relative/preset moves set the position directly.
class PtzService implements OnvifService {
  final DeviceState state;

  PtzService({required this.state});

  static const _panTiltPositionSpace =
      'http://www.onvif.org/ver10/tptz/PanTiltSpaces/PositionGenericSpace';
  static const _zoomPositionSpace =
      'http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace';
  static const _panTiltVelocitySpace =
      'http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace';
  static const _zoomVelocitySpace =
      'http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace';

  @override
  bool handles(String namespace) => namespace == Xmlns.tptz;

  @override
  bool isPreAuth(String operation) => operation == 'GetServiceCapabilities';

  @override
  Future<String> handle(RequestContext ctx, {required String host}) async {
    switch (ctx.operation) {
      case 'GetConfigurations':
        return _getConfigurations();
      case 'GetConfiguration':
        return _getConfiguration();
      case 'GetCompatibleConfigurations':
        return _getCompatibleConfigurations();
      case 'GetConfigurationOptions':
        return _getConfigurationOptions();
      case 'GetStatus':
        return _getStatus();
      case 'GetServiceCapabilities':
        return _getServiceCapabilities();
      case 'GetPresets':
        return _getPresets();
      case 'GetPresetTours':
        // Preset tours are supported as a call but no tours exist.
        return _empty('GetPresetToursResponse');
      case 'GetPresetTour':
        return SoapEnvelopeBuilder.fault(
          subcode: 'NoToken',
          reason: 'No preset tour exists for the requested token.',
        );
      case 'SetPreset':
        return _setPreset(ctx);
      case 'RemovePreset':
        return _removePreset(ctx);
      case 'GotoPreset':
        return _gotoPreset(ctx);
      case 'GotoHomePosition':
        state.gotoHomePosition();
        return _empty('GotoHomePositionResponse');
      case 'SetHomePosition':
        state.setHomePosition();
        return _empty('SetHomePositionResponse');
      case 'ContinuousMove':
        return _continuousMove(ctx);
      case 'AbsoluteMove':
        return _absoluteMove(ctx);
      case 'RelativeMove':
        return _relativeMove(ctx);
      case 'Stop':
        state.stop();
        return _empty('StopResponse');
      default:
        return SoapEnvelopeBuilder.fault(
          subcode: 'ActionNotSupported',
          reason: 'The requested action is not supported by this device.',
        );
    }
  }

  // ── Configurations ───────────────────────────────────────────────────────

  String _getConfigurations() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetConfigurationsResponse',
        namespaceUri: Xmlns.tptz,
        nest: () {
          _writePtzConfiguration(b);
        },
      );
    });
  }

  String _getConfiguration() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetConfigurationResponse',
        namespaceUri: Xmlns.tptz,
        nest: () {
          _writePtzConfiguration(b);
        },
      );
    });
  }

  String _getCompatibleConfigurations() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetCompatibleConfigurationsResponse',
        namespaceUri: Xmlns.tptz,
        nest: () {
          _writePtzConfiguration(b);
        },
      );
    });
  }

  String _getConfigurationOptions() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetConfigurationOptionsResponse',
        namespaceUri: Xmlns.tptz,
        nest: () {
          b.element(
            'PTZConfigurationOptions',
            namespaceUri: Xmlns.tptz,
            nest: () {
              b.element(
                'Spaces',
                namespaceUri: Xmlns.tt,
                nest: () {
                  _writeSpace2D(
                    b,
                    'AbsolutePanTiltPositionSpace',
                    _panTiltPositionSpace,
                    -1,
                    1,
                    -1,
                    1,
                  );
                  _writeSpace1D(
                    b,
                    'AbsoluteZoomPositionSpace',
                    _zoomPositionSpace,
                    0,
                    1,
                  );
                  _writeSpace2D(
                    b,
                    'ContinuousPanTiltVelocitySpace',
                    _panTiltVelocitySpace,
                    -1,
                    1,
                    -1,
                    1,
                  );
                  _writeSpace1D(
                    b,
                    'ContinuousZoomVelocitySpace',
                    _zoomVelocitySpace,
                    -1,
                    1,
                  );
                },
              );
              b.element(
                'PTZTimeout',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element('Min', namespaceUri: Xmlns.tt, nest: 'PT0S');
                  b.element('Max', namespaceUri: Xmlns.tt, nest: 'PT300S');
                },
              );
            },
          );
        },
      );
    });
  }

  // ── Status ───────────────────────────────────────────────────────────────

  String _getStatus() {
    final position = state.position;

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetStatusResponse',
        namespaceUri: Xmlns.tptz,
        nest: () {
          b.element(
            'PTZStatus',
            namespaceUri: Xmlns.tptz,
            nest: () {
              b.element(
                'Position',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element(
                    'PanTilt',
                    namespaceUri: Xmlns.tt,
                    attributes: {
                      'x': position.pan.toString(),
                      'y': position.tilt.toString(),
                      'space': _panTiltPositionSpace,
                    },
                  );
                  b.element(
                    'Zoom',
                    namespaceUri: Xmlns.tt,
                    attributes: {
                      'x': position.zoom.toString(),
                      'space': _zoomPositionSpace,
                    },
                  );
                },
              );
              b.element(
                'MoveStatus',
                namespaceUri: Xmlns.tt,
                nest: () {
                  b.element('PanTilt', namespaceUri: Xmlns.tt, nest: 'IDLE');
                  b.element('Zoom', namespaceUri: Xmlns.tt, nest: 'IDLE');
                },
              );
              b.element(
                'UtcTime',
                namespaceUri: Xmlns.tt,
                nest: DateTime.now().toUtc().toIso8601String(),
              );
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
        namespaceUri: Xmlns.tptz,
        nest: () {
          b.element(
            'Capabilities',
            namespaceUri: Xmlns.tptz,
            attributes: {'EFlip': 'false', 'Reverse': 'false'},
          );
        },
      );
    });
  }

  // ── Presets ──────────────────────────────────────────────────────────────

  String _getPresets() {
    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'GetPresetsResponse',
        namespaceUri: Xmlns.tptz,
        nest: () {
          for (final preset in state.presets.values) {
            b.element(
              'Preset',
              namespaceUri: Xmlns.tptz,
              attributes: {'token': preset.token},
              nest: () {
                b.element('Name', namespaceUri: Xmlns.tt, nest: preset.name);
                b.element(
                  'PTZPosition',
                  namespaceUri: Xmlns.tt,
                  nest: () {
                    b.element(
                      'PanTilt',
                      namespaceUri: Xmlns.tt,
                      attributes: {
                        'x': preset.position.pan.toString(),
                        'y': preset.position.tilt.toString(),
                        'space': _panTiltPositionSpace,
                      },
                    );
                    b.element(
                      'Zoom',
                      namespaceUri: Xmlns.tt,
                      attributes: {
                        'x': preset.position.zoom.toString(),
                        'space': _zoomPositionSpace,
                      },
                    );
                  },
                );
              },
            );
          }
        },
      );
    });
  }

  String _setPreset(RequestContext ctx) {
    final name = ctx.param('PresetName');
    final token = ctx.param('PresetToken');

    final presetToken = state.setPreset(name, token);

    return SoapEnvelopeBuilder.response((b) {
      b.element(
        'SetPresetResponse',
        namespaceUri: Xmlns.tptz,
        nest: () {
          b.element('PresetToken', namespaceUri: Xmlns.tptz, nest: presetToken);
        },
      );
    });
  }

  String _removePreset(RequestContext ctx) {
    final token = ctx.param('PresetToken');

    if (token != null) state.removePreset(token);

    return _empty('RemovePresetResponse');
  }

  String _gotoPreset(RequestContext ctx) {
    final token = ctx.param('PresetToken');

    if (token != null) state.gotoPreset(token);

    return _empty('GotoPresetResponse');
  }

  // ── Movement ─────────────────────────────────────────────────────────────

  String _continuousMove(RequestContext ctx) {
    final velocity = _vector(ctx, 'Velocity');

    state.continuousMove(
      pan: velocity.$1,
      tilt: velocity.$2,
      zoom: velocity.$3,
    );

    return _empty('ContinuousMoveResponse');
  }

  String _absoluteMove(RequestContext ctx) {
    final position = _vector(ctx, 'Position');

    state.absoluteMove(
      PtzVector(pan: position.$1, tilt: position.$2, zoom: position.$3),
    );

    return _empty('AbsoluteMoveResponse');
  }

  String _relativeMove(RequestContext ctx) {
    final translation = _vector(ctx, 'Translation');

    state.relativeMove(
      PtzVector(
        pan: translation.$1,
        tilt: translation.$2,
        zoom: translation.$3,
      ),
    );

    return _empty('RelativeMoveResponse');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Reads a `(PanTilt x, PanTilt y, Zoom x)` triple from the named child
  /// element (e.g. `Velocity`, `Position`, `Translation`).
  (double, double, double) _vector(RequestContext ctx, String wrapperName) {
    double pan = 0;
    double tilt = 0;
    double zoom = 0;

    final wrapper = ctx.operationElement.childElements
        .where((e) => e.localName == wrapperName)
        .firstOrNull;

    if (wrapper != null) {
      for (final child in wrapper.childElements) {
        if (child.localName == 'PanTilt') {
          pan = double.tryParse(child.getAttribute('x') ?? '0') ?? 0;
          tilt = double.tryParse(child.getAttribute('y') ?? '0') ?? 0;
        } else if (child.localName == 'Zoom') {
          zoom = double.tryParse(child.getAttribute('x') ?? '0') ?? 0;
        }
      }
    }

    return (pan, tilt, zoom);
  }

  void _writePtzConfiguration(XmlBuilder b) {
    b.element(
      'PTZConfiguration',
      namespaceUri: Xmlns.tptz,
      attributes: {'token': DeviceState.ptzConfigurationToken},
      nest: () {
        b.element('Name', namespaceUri: Xmlns.tt, nest: 'PTZ Configuration');
        b.element('UseCount', namespaceUri: Xmlns.tt, nest: '1');
        b.element('NodeToken', namespaceUri: Xmlns.tt, nest: 'PTZNode_1');
        b.element(
          'DefaultPTZSpeed',
          namespaceUri: Xmlns.tt,
          nest: () {
            b.element(
              'PanTilt',
              namespaceUri: Xmlns.tt,
              attributes: {'x': '0.5', 'y': '0.5'},
            );
            b.element('Zoom', namespaceUri: Xmlns.tt, attributes: {'x': '1.0'});
          },
        );
        b.element('DefaultPTZTimeout', namespaceUri: Xmlns.tt, nest: 'PT300S');
        b.element(
          'PanTiltLimits',
          namespaceUri: Xmlns.tt,
          nest: () {
            b.element(
              'Range',
              namespaceUri: Xmlns.tt,
              nest: () {
                b.element(
                  'URI',
                  namespaceUri: Xmlns.tt,
                  nest: _panTiltPositionSpace,
                );
                _writeRange(b, -1, 1, includeY: true);
              },
            );
          },
        );
        b.element(
          'ZoomLimits',
          namespaceUri: Xmlns.tt,
          nest: () {
            b.element(
              'Range',
              namespaceUri: Xmlns.tt,
              nest: () {
                b.element('URI', namespaceUri: Xmlns.tt, nest: _zoomPositionSpace);
                _writeRange(b, 0, 1, includeY: false);
              },
            );
          },
        );
      },
    );
  }

  void _writeRange(XmlBuilder b, num minX, num maxX, {required bool includeY}) {
    b.element(
      'XRange',
      namespaceUri: Xmlns.tt,
      nest: () {
        b.element('Min', namespaceUri: Xmlns.tt, nest: '$minX');
        b.element('Max', namespaceUri: Xmlns.tt, nest: '$maxX');
      },
    );
    if (includeY) {
      b.element(
        'YRange',
        namespaceUri: Xmlns.tt,
        nest: () {
          b.element('Min', namespaceUri: Xmlns.tt, nest: '$minX');
          b.element('Max', namespaceUri: Xmlns.tt, nest: '$maxX');
        },
      );
    }
  }

  void _writeSpace2D(
    XmlBuilder b,
    String tag,
    String uri,
    num minX,
    num maxX,
    num minY,
    num maxY,
  ) {
    b.element(
      tag,
      namespaceUri: Xmlns.tt,
      nest: () {
        b.element('URI', namespaceUri: Xmlns.tt, nest: uri);
        b.element(
          'XRange',
          namespaceUri: Xmlns.tt,
          nest: () {
            b.element('Min', namespaceUri: Xmlns.tt, nest: '$minX');
            b.element('Max', namespaceUri: Xmlns.tt, nest: '$maxX');
          },
        );
        b.element(
          'YRange',
          namespaceUri: Xmlns.tt,
          nest: () {
            b.element('Min', namespaceUri: Xmlns.tt, nest: '$minY');
            b.element('Max', namespaceUri: Xmlns.tt, nest: '$maxY');
          },
        );
      },
    );
  }

  void _writeSpace1D(XmlBuilder b, String tag, String uri, num min, num max) {
    b.element(
      tag,
      namespaceUri: Xmlns.tt,
      nest: () {
        b.element('URI', namespaceUri: Xmlns.tt, nest: uri);
        b.element(
          'XRange',
          namespaceUri: Xmlns.tt,
          nest: () {
            b.element('Min', namespaceUri: Xmlns.tt, nest: '$min');
            b.element('Max', namespaceUri: Xmlns.tt, nest: '$max');
          },
        );
      },
    );
  }

  String _empty(String responseName) {
    return SoapEnvelopeBuilder.response((b) {
      b.element(responseName, namespaceUri: Xmlns.tptz, nest: () {});
    });
  }
}
