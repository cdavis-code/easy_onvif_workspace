import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/util.dart';
import 'package:xml/xml.dart';

import '../model/media2/webrtc_configuration.dart';
import 'media_common.dart';
import 'transport.dart';
import 'xmlns.dart';

class Media2Request {
  static XmlBuilder get builder => Transport.builder;

  /// XML for the [deleteProfile]
  static XmlDocumentFragment deleteProfile(String referenceToken) {
    builder.element(
      'DeleteProfile',
      nest: () {
        builder.namespaceUri(null, Xmlns.tr2);

        ReferenceToken(referenceToken).buildXml(builder, tag: 'Token');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getMetadataConfigurationOptions]
  static XmlDocumentFragment getMetadataConfigurationOptions({
    String? configurationToken,
    String? profileToken,
  }) => MediaCommon.getMetadataConfigurationOptions(
    configurationToken: configurationToken,
    profileToken: profileToken,
    namespace: Xmlns.tr2,
  );

  /// XML for the [getMetadataConfigurations]
  static XmlDocumentFragment getMetadataConfigurations({
    String? configurationToken,
    String? profileToken,
  }) => MediaCommon.getMetadataConfigurations(
    configurationToken: configurationToken,
    profileToken: profileToken,
    namespace: Xmlns.tr2,
  );

  /// XML for the [getProfiles]
  static XmlDocumentFragment getProfiles() =>
      Transport.quickTag('GetProfiles', Xmlns.tr2);

  /// XML for the [getServiceCapabilities]
  static XmlDocumentFragment getServiceCapabilities() =>
      Transport.quickTag('GetServiceCapabilities', Xmlns.tr2);

  /// XML for the [getSnapshotUri], requires a [profileToken]
  static XmlDocumentFragment getSnapshotUri(String profileToken) {
    builder.element(
      'GetSnapshotUri',
      nest: () {
        builder.namespaceUri(null, Xmlns.tr2);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getStreamUri], requires a [profileToken]
  static XmlDocumentFragment getStreamUri(
    String profileToken, {
    String protocol = 'RTSP',
  }) {
    builder.element(
      'GetStreamUri',
      nest: () {
        builder.namespaceUri(null, Xmlns.tr2);

        protocol.buildXml(builder, tag: 'Protocol');

        builder.element(
          'Protocol',
          nest: () {
            builder.namespaceUri(null, Xmlns.tt);
            builder.text(protocol);
          },
        );

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [videoEncoderConfigurations]
  static XmlDocumentFragment videoEncoderConfigurations({
    String? configurationToken,
    String? profileToken,
  }) {
    builder.element(
      'GetVideoEncoderConfigurations',
      nest: () {
        builder.namespaceUri(null, Xmlns.tr2);

        if (configurationToken != null) {
          ReferenceToken(
            configurationToken,
          ).buildXml(builder, tag: 'ConfigurationToken');
        }

        if (profileToken != null) {
          ReferenceToken(profileToken).buildXml(builder, tag: 'ProfileToken');
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getVideoEncoderInstances]
  static XmlDocumentFragment getVideoEncoderInstances(
    String configurationToken,
  ) {
    builder.element(
      'GetVideoEncoderInstances',
      nest: () {
        builder.namespaceUri(null, Xmlns.tr2);

        ReferenceToken(
          configurationToken,
        ).buildXml(builder, tag: 'ConfigurationToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getVideoSourceConfigurationOptions]
  static XmlDocumentFragment getVideoSourceConfigurationOptions({
    String? configurationToken,
    String? profileToken,
  }) {
    builder.element(
      'GetVideoSourceConfigurationOptions',
      nest: () {
        builder.namespaceUri(null, Xmlns.tr2);

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
  static XmlDocumentFragment startMulticastStreaming(String profileToken) =>
      MediaCommon.startMulticastStreaming(
        profileToken: profileToken,
        namespace: Xmlns.tr2,
      );

  /// XML for the [stopMulticastStreaming]
  static XmlDocumentFragment stopMulticastStreaming(String profileToken) =>
      MediaCommon.stopMulticastStreaming(
        profileToken: profileToken,
        namespace: Xmlns.tr2,
      );

  /// XML for the [getWebRTCConfigurations]
  static XmlDocumentFragment getWebRTCConfigurations() =>
      Transport.quickTag('GetWebRTCConfigurations', Xmlns.tr2);

  /// XML for the [setWebRTCConfigurations]
  static XmlDocumentFragment setWebRTCConfigurations(
    List<WebrtcConfiguration> configurations,
  ) {
    builder.element(
      'SetWebRTCConfigurations',
      nest: () {
        builder.namespaceUri(null, Xmlns.tr2);

        for (var configuration in configurations) {
          configuration.buildXml(builder);
        }
      },
    );

    return builder.buildFragment();
  }
}
