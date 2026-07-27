import 'package:easy_onvif/media1.dart' show StreamSetup;
import 'package:easy_onvif/replay.dart';
import 'package:easy_onvif/shared.dart';
import 'package:xml/xml.dart';

import 'transport.dart';
import 'xmlns.dart';

class ReplayRequest {
  static XmlBuilder get builder => Transport.builder;

  /// XML for the [getReplayConfiguration]
  static XmlDocumentFragment getReplayConfiguration() =>
      Transport.quickTag('GetReplayConfiguration', Xmlns.trp);

  /// XML for the [getReplayUri]
  static XmlDocumentFragment getReplayUri(
    String recordingToken, {
    required StreamSetup streamSetup,
  }) {
    builder.element(
      'GetReplayUri',
      nest: () {
        builder.namespaceUri(null, Xmlns.trp);

        streamSetup.buildXml(builder);

        ReferenceToken(recordingToken).buildXml(builder, tag: 'RecordingToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getServiceCapabilities]
  static XmlDocumentFragment getServiceCapabilities() =>
      Transport.quickTag('GetServiceCapabilities', Xmlns.trp);

  /// XML for the [setReplayConfiguration]
  static XmlDocumentFragment setReplayConfiguration(
    ReplayConfiguration configuration,
  ) {
    builder.element(
      'SetReplayConfiguration',
      nest: () {
        builder.namespaceUri(null, Xmlns.trp);

        configuration.buildXml(builder);
      },
    );

    return builder.buildFragment();
  }
}
