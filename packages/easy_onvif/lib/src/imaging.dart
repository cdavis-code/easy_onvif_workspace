import 'package:easy_onvif/imaging.dart';
import 'package:easy_onvif/soap.dart' as soap;

import 'operation.dart';

typedef ImagingRequest = soap.ImagingRequest;

/// The imaging service provides configuration and control data for imaging
/// specific properties.
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
class Imaging extends Operation {
  Imaging({required super.transport, required super.uri});

  /// Via this command the last Imaging Preset applied can be requested. If the
  /// camera configuration does not match any of the existing Imaging Presets,
  /// the output of GetCurrentPreset shall be Empty. GetCurrentPreset shall
  /// return 0 if Imaging Presets are not supported by the Video Source.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<ImagingPreset> getCurrentPreset(
    String videoSourceToken, {
    int? limit = 100,
  }) async {
    loggy.debug('getCurrentPreset');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: ImagingRequest.getCurrentPreset(videoSourceToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetCurrentPresetResponse.fromJson(
      responseEnvelope.body.response!,
    ).preset;
  }

  /// Via this command the list of available Imaging Presets can be requested.
  ///
  /// ACCESS CLASS: READ_MEDIA
  Future<List<ImagingPreset>> getPresets(
    String videoSourceToken, {
    int? limit = 100,
  }) async {
    loggy.debug('getPresets');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: ImagingRequest.getPresets(videoSourceToken)),
    );

    if (responseEnvelope.body.response == null) throw Exception();

    final presets = GetPresetsResponse.fromJson(
      responseEnvelope.body.response!,
    ).presets;

    limit = (limit! > presets.length) ? presets.length : limit;

    return GetPresetsResponse.fromJson(
      responseEnvelope.body.response!,
    ).presets.sublist(0, limit);
  }

  /// Returns the capabilities of the imaging service. The result is returned in
  /// a typed answer.
  ///
  /// Access Class: PRE_AUTH
  Future<Capabilities> getServiceCapabilities() async {
    loggy.debug('getServiceCapabilities');

    final responseEnvelope = await transport.request(
      uri,
      soap.Body(request: ImagingRequest.getServiceCapabilities()),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetServiceCapabilitiesResponse.fromJson(
      responseEnvelope.body.response!,
    ).capabilities;
  }

  /// Via this command the current status of the Move operation can be requested.
  /// Supported for this command is available if the support for the Move
  /// operation is signalled via GetMoveOptions.
  ///
  /// Access Class: READ_MEDIA
  Future<ImagingStatus20> getStatus(String videoSourceToken) async {
    loggy.debug('getStatus');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(request: ImagingRequest.getStatus(videoSourceToken)),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return GetStatusResponse.fromJson(
      responseEnvelope.body.response!,
    ).imagingStatus20;
  }

  /// The [setCurrentPreset] command shall request a given Imaging Preset to be
  /// applied to the specified Video Source. SetCurrentPreset shall only be
  /// available for Video Sources with Imaging Presets Capability. Imaging
  /// Presets are defined by the Manufacturer, and offered as a tool to simplify
  /// Imaging Settings adjustments for specific scene content. When the new
  /// Imaging Preset is applied by SetCurrentPreset, the Device shall adjust the
  /// Video Source settings to match those defined by the specified Imaging
  /// Preset.
  ///
  /// Access Class: ACTUATE
  Future<bool> setCurrentPreset({
    required String videoSourceToken,
    required String presetToken,
  }) async {
    loggy.debug('setCurrentPreset');

    final responseEnvelope = await transport.securedRequest(
      uri,
      soap.Body(
        request: ImagingRequest.setCurrentPreset(
          videoSourceToken: videoSourceToken,
          presetToken: presetToken,
        ),
      ),
    );

    if (responseEnvelope.body.hasFault) {
      throw Exception(responseEnvelope.body.fault.toString());
    }

    return true;
  }
}
