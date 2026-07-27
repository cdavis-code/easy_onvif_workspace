import 'package:easy_onvif/shared.dart';
import 'package:xml/xml.dart';

import 'transport.dart';
import 'xmlns.dart';

class ImagingRequest {
  static XmlBuilder get builder => Transport.builder;

  /// XML for the [getCurrentPreset], requires a [videoSourceToken]
  static XmlDocumentFragment getCurrentPreset(String videoSourceToken) {
    Transport.builder.element(
      'GetCurrentPreset',
      nest: () {
        Transport.builder.namespaceUri(null, Xmlns.timg);

        ReferenceToken(
          videoSourceToken,
        ).buildXml(builder, tag: 'VideoSourceToken');
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [getPresets], requires a [videoSourceToken]
  static XmlDocumentFragment getPresets(String videoSourceToken) {
    Transport.builder.element(
      'GetPresets',
      nest: () {
        Transport.builder.namespaceUri(null, Xmlns.timg);

        ReferenceToken(
          videoSourceToken,
        ).buildXml(builder, tag: 'VideoSourceToken');
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [getServiceCapabilities]
  static XmlDocumentFragment getServiceCapabilities() =>
      Transport.quickTag('GetServiceCapabilities', Xmlns.timg);

  /// XML for the [getStatus], requires a [videoSourceToken]
  static XmlDocumentFragment getStatus(String videoSourceToken) {
    Transport.builder.element(
      'GetStatus',
      nest: () {
        Transport.builder.namespaceUri(null, Xmlns.timg);

        ReferenceToken(
          videoSourceToken,
        ).buildXml(builder, tag: 'VideoSourceToken');
      },
    );

    return Transport.builder.buildFragment();
  }

  /// XML for the [setCurrentPreset], requires a [videoSourceToken]
  static XmlDocumentFragment setCurrentPreset({
    required String videoSourceToken,
    required String presetToken,
  }) {
    Transport.builder.element(
      'SetPreset',
      nest: () {
        Transport.builder.namespaceUri(null, Xmlns.timg);

        ReferenceToken(
          videoSourceToken,
        ).buildXml(builder, tag: 'VideoSourceToken');

        ReferenceToken(videoSourceToken).buildXml(builder, tag: 'PresetToken');
      },
    );

    return Transport.builder.buildFragment();
  }
}
