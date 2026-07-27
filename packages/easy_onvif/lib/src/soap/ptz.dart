import 'package:easy_onvif/ptz.dart';
import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/util.dart';
import 'package:xml/xml.dart';

import 'transport.dart';
import 'xmlns.dart';

class PtzRequest {
  static XmlBuilder get builder => Transport.builder;

  static XmlDocumentFragment absoluteMove(
    String profileToken, {
    required PtzVector position,
    PtzSpeed? speed,
  }) {
    builder.element(
      'AbsoluteMove',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz); //tptz

        ReferenceToken(profileToken).buildXml(builder);

        position.buildXml(builder, tag: 'Position', namespace: Xmlns.tptz);

        speed?.buildXml(builder, tag: 'Speed', namespace: Xmlns.tptz);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [continuousMove], requires a [profileToken] and [PtzSpeed],
  /// and optionally [timeout] in seconds
  static XmlDocumentFragment continuousMove(
    String profileToken, {
    required PtzSpeed velocity,
    int? timeout,
  }) {
    builder.element(
      'ContinuousMove',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);

        velocity.buildXml(builder, tag: 'Velocity', namespace: Xmlns.tptz);

        if (timeout != null) {
          'PT${timeout}S'.buildXml(
            builder,
            tag: 'Timeout',
            namespace: Xmlns.tptz,
          );
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getCompatibleConfigurations], requires a [profileToken]
  static XmlDocumentFragment getCompatibleConfigurations(String profileToken) {
    builder.element(
      'GetCompatibleConfigurations',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getConfiguration], requires a [profileToken]
  static XmlDocumentFragment getConfiguration(String profileToken) {
    builder.element(
      'GetConfiguration',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(
          profileToken,
        ).buildXml(builder, tag: 'PTZConfigurationToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getConfigurationOptions], requires a [profileToken]
  static XmlDocumentFragment getConfigurationOptions(String profileToken) {
    builder.element(
      'GetConfigurationOptions',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(
          profileToken,
        ).buildXml(builder, tag: 'ConfigurationToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getConfigurations]
  static XmlDocumentFragment getConfigurations() =>
      Transport.quickTag('GetConfigurations', Xmlns.tptz);

  /// XML for the [getPresets], requires a [profileToken]
  static XmlDocumentFragment getPresets(String profileToken) {
    builder.element(
      'GetPresets',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getPresetTour], requires a [profileToken] and [presetTourToken]
  static XmlDocumentFragment getPresetTour(
    String profileToken, {
    required String presetTourToken,
  }) {
    builder.element(
      'GetPresetTour',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);

        ReferenceToken(
          presetTourToken,
        ).buildXml(builder, tag: 'PresetTourToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getPresetTours], requires a [profileToken]
  static XmlDocumentFragment getPresetTours(String profileToken) {
    builder.element(
      'GetPresetTours',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [getServiceCapabilities]
  static XmlDocumentFragment getServiceCapabilities() =>
      Transport.quickTag('GetServiceCapabilities', Xmlns.tptz);

  /// XML for the [getStatus], requires a [profileToken]
  static XmlDocumentFragment getStatus(String profileToken) {
    builder.element(
      'GetStatus',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [gotoHomePosition], requires a [profileToken] and optionally [PtzSpeed]
  static XmlDocumentFragment gotoHomePosition(
    String profileToken, {
    PtzSpeed? speed,
  }) {
    builder.element(
      'GotoHomePosition',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);

        speed?.buildXml(builder, tag: 'Speed', namespace: Xmlns.tptz);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [gotoPreset], requires a [profileToken], [presetToken] and optionally [PtzSpeed]
  static XmlDocumentFragment gotoPreset(
    String profileToken, {
    required String presetToken,
    PtzSpeed? speed,
  }) {
    builder.element(
      'GotoPreset',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);

        ReferenceToken(presetToken).buildXml(builder, tag: 'PresetToken');

        speed?.buildXml(builder, tag: 'Speed', namespace: Xmlns.tptz);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [relativeMove], requires a [profileToken] and [PtzVector]
  static XmlDocumentFragment relativeMove(
    String profileToken, {
    required PtzVector translation,
    PtzSpeed? speed,
  }) {
    builder.element(
      'RelativeMove',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz); //tptz

        ReferenceToken(profileToken).buildXml(builder, namespace: Xmlns.tptz);

        translation.buildXml(
          builder,
          tag: 'Translation',
          namespace: Xmlns.tptz,
        );

        speed?.buildXml(builder, tag: 'Speed', namespace: Xmlns.tptz);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [removePreset], requires a [profileToken] and [Preset]
  static XmlDocumentFragment removePreset(
    String profileToken, {
    required Preset preset,
  }) {
    builder.element(
      'RemovePreset',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);

        preset.referenceToken.buildXml(builder, tag: 'PresetToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [removePresetTour], requires a [profileToken] and [presetTour]
  static XmlDocumentFragment removePresetTour(
    String profileToken, {
    required PresetTour presetTour,
  }) {
    builder.element(
      'RemovePresetTour',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);

        presetTour.referenceToken.buildXml(builder, tag: 'PresetTourToken');
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setHomePosition], requires a [profileToken]
  static XmlDocumentFragment setHomePosition(String profileToken) {
    builder.element(
      'SetHomePosition',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [setPreset], requires a [profileToken] and optionally
  /// [presetName] and/or [presetToken]
  static XmlDocumentFragment setPreset(
    String profileToken, {
    String? presetName,
    String? presetToken,
  }) {
    builder.element(
      'SetPreset',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);

        presetName?.toString().buildXml(
          builder,
          tag: 'PresetName',
          namespace: Xmlns.tptz,
        );

        if (presetToken != null) {
          ReferenceToken(
            presetToken,
          ).buildXml(builder, tag: 'PresetToken', namespace: Xmlns.tptz);
        }
      },
    );

    return builder.buildFragment();
  }

  /// XML for the [stop], requires a [profileToken] and optionally [panTilt]
  /// and/or [zoom]
  static XmlDocumentFragment stop(
    String profileToken, {
    bool panTilt = true,
    bool zoom = true,
  }) {
    // the Onvif spec says that a continuous move with Velocity of 0 is the
    // same as a stop
    final velocity = PtzSpeed(
      panTilt: panTilt ? Vector2D.fromDouble(x: 0, y: 0) : null,
      zoom: zoom ? Vector1D.fromDouble(0) : null,
    );

    builder.element(
      'ContinuousMove',
      nest: () {
        builder.namespaceUri(null, Xmlns.tptz);

        ReferenceToken(profileToken).buildXml(builder);

        velocity.buildXml(builder, tag: 'Velocity', namespace: Xmlns.tptz);
      },
    );

    // builder.element(
    //   'Stop',
    //   nest: () {
    //     builder.namespaceUri(null, Xmlns.tptz); //tptz

    //     ReferenceToken(profileToken).buildXml(builder);

    //     panTilt.toString().buildXml(
    //       builder,
    //       tag: 'PanTilt',
    //       namespace: Xmlns.tt,
    //     );

    //     zoom.toString().buildXml(builder, tag: 'Zoom', namespace: Xmlns.tt);
    //   },
    // );

    return builder.buildFragment();
  }
}
