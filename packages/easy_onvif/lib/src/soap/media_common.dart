import 'package:easy_onvif/shared.dart';
import 'package:xml/xml.dart';

import 'transport.dart';

class MediaCommon {
  static XmlBuilder get builder => Transport.builder;

  /// XML for the [getMetadataConfigurationOptions]
  static XmlDocumentFragment getMetadataConfigurationOptions({
    String? configurationToken,
    String? profileToken,
    required String namespace,
  }) {
    builder.element(
      'GetMetadataConfigurationOptions',
      nest: () {
        builder.namespaceUri(null, namespace);

        if (configurationToken != null) {
          ReferenceToken(
            configurationToken,
          ).buildXml(builder, tag: 'ConfigurationToken');
        }

        if (profileToken != null) {
          ReferenceToken(profileToken).buildXml(builder);
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getMetadataConfigurations]
  static XmlDocumentFragment getMetadataConfigurations({
    String? configurationToken,
    String? profileToken,
    required String namespace,
  }) {
    builder.element(
      'GetMetadataConfigurations',
      nest: () {
        builder.namespaceUri(null, namespace);

        if (configurationToken != null) {
          ReferenceToken(
            configurationToken,
          ).buildXml(builder, tag: 'ConfigurationToken');
        }

        if (profileToken != null) {
          ReferenceToken(profileToken).buildXml(builder);
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [startMulticastStreaming]
  static XmlDocumentFragment startMulticastStreaming({
    required String profileToken,
    required String namespace,
  }) {
    builder.element(
      'StartMulticastStreaming',
      nest: () {
        builder.namespaceUri(null, namespace);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [stopMulticastStreaming]
  static XmlDocumentFragment stopMulticastStreaming({
    required String profileToken,
    required String namespace,
  }) {
    builder.element(
      'StopMulticastStreaming',
      nest: () {
        builder.namespaceUri(null, namespace);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }
}
