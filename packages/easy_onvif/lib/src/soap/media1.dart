import 'package:easy_onvif/media1.dart' hide Transport;
import 'package:easy_onvif/shared.dart';
import 'package:xml/xml.dart';

import 'media_common.dart';
import 'transport.dart';
import 'xmlns.dart';

class MediaRequest {
  static XmlBuilder get builder => Transport.builder;

  /// XML for the [getAudioSources]
  static XmlDocumentFragment getAudioSources() =>
      Transport.quickTag('GetAudioSources', Xmlns.trt);

  /// XML for the [getAudioOutputs]
  static XmlDocumentFragment getAudioOutputs() =>
      Transport.quickTag('GetAudioOutputs', Xmlns.trt);

  /// XML for the [getMetadataConfiguration]
  static XmlDocumentFragment getMetadataConfiguration(
    String configurationToken,
  ) {
    builder.element(
      'GetMetadataConfiguration',
      nest: () {
        builder.namespaceUri(null, Xmlns.trt);

        ReferenceToken(
          configurationToken,
        ).buildXml(builder, tag: 'ConfigurationToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getMetadataConfigurationOptions]
  static XmlDocumentFragment getMetadataConfigurationOptions({
    String? configurationToken,
    String? profileToken,
    required String namespace,
  }) => MediaCommon.getMetadataConfigurationOptions(
    configurationToken: configurationToken,
    profileToken: profileToken,
    namespace: Xmlns.trt,
  );

  /// XML for the [getMetadataConfigurations]
  static XmlDocumentFragment getMetadataConfigurations({
    String? configurationToken,
    String? profileToken,
  }) => MediaCommon.getMetadataConfigurations(
    configurationToken: configurationToken,
    profileToken: profileToken,
    namespace: Xmlns.trt,
  );

  /// XML for the [getProfile], requires a [profileToken]
  static XmlDocumentFragment getProfile(String profileToken) {
    builder.element(
      'GetProfile',
      nest: () {
        builder.namespaceUri(null, Xmlns.trt);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getProfiles]
  static XmlDocumentFragment getProfiles() =>
      Transport.quickTag('GetProfiles', Xmlns.trt);

  /// XML for the [getServiceCapabilities]
  static XmlDocumentFragment getServiceCapabilities() =>
      Transport.quickTag('GetServiceCapabilities', Xmlns.trt);

  /// XML for the [getSnapshotUri], requires a [profileToken]
  static XmlDocumentFragment getSnapshotUri(
    String profileToken, {
    StreamSetup? streamSetup,
  }) {
    builder.element(
      'GetSnapshotUri',
      nest: () {
        builder.namespaceUri(null, Xmlns.trt);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getStreamUri], requires a [profileToken]
  static XmlDocumentFragment getStreamUri(
    String profileToken, {
    required StreamSetup streamSetup,
  }) {
    builder.element(
      'GetStreamUri',
      nest: () {
        builder.namespaceUri(null, Xmlns.trt);

        streamSetup.buildXml(builder);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getVideoSources]
  static XmlDocumentFragment getVideoSources() =>
      Transport.quickTag('GetVideoSources', Xmlns.trt);

  /// XML for the [startMulticastStreaming]
  static XmlDocumentFragment startMulticastStreaming(String profileToken) =>
      MediaCommon.startMulticastStreaming(
        profileToken: profileToken,
        namespace: Xmlns.trt,
      );

  /// XML for the [stopMulticastStreaming]
  static XmlDocumentFragment stopMulticastStreaming(String profileToken) =>
      MediaCommon.stopMulticastStreaming(
        profileToken: profileToken,
        namespace: Xmlns.trt,
      );
}
