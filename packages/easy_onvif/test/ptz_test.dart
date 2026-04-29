import 'package:easy_onvif/ptz.dart';
import 'package:test/test.dart';

import 'envelope.dart';

void main() {
  group("PTZ", () {
    group("Happytimesoft", () {
      test('AbsoluteMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/AbsoluteMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('AbsoluteMoveResponse'),
          true,
        );
      });

      test('ContinuousMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/ContinuousMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('ContinuousMoveResponse'),
          true,
        );
      });

      test('GetCompatibleConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/GetCompatibleConfigurationsResponse.xml',
        );

        expect(
          GetCompatibleConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/GetConfigurationResponse.xml',
        );

        expect(
          GetConfigurationResponse.fromJson(
            envelope.body.response!,
          ).ptzConfiguration.useCount,
          2,
        );
      });

      test('GetConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/GetConfigurationOptionsResponse.xml',
        );

        expect(
          GetConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurationOptions.ptzTimeout.min,
          'PT1S',
        );
      });

      test('GetConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/GetConfigurationsResponse.xml',
        );

        expect(
          GetConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetPresetsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/GetPresetsResponse.xml',
        );

        expect(
          GetPresetsResponse.fromJson(envelope.body.response!).presets.isEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities?.eFlip,
          true,
        );
      });

      test('GetStatusResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/GetStatusResponse.xml',
        );

        expect(
          GetStatusResponse.fromJson(envelope.body.response!).ptzStatus.error,
          null,
        );
      });

      test('GotoHomePositionResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/GotoHomePositionResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('GotoHomePositionResponse'),
          true,
        );
      });

      test('RelativeMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/RelativeMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('RelativeMoveResponse'),
          true,
        );
      });

      test('StopResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/ptz/StopResponse.xml',
        );

        expect(envelope.body.response!.containsKey('StopResponse'), true);
      });
    });

    group("ENP1A14-IR_25X", () {
      test('AbsoluteMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/AbsoluteMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('AbsoluteMoveResponse'),
          true,
        );
      });

      test('ContinuousMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/ContinuousMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('ContinuousMoveResponse'),
          true,
        );
      });

      test('GetCompatibleConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GetCompatibleConfigurationsResponse.xml',
        );

        expect(
          GetCompatibleConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GetConfigurationResponse.xml',
        );

        expect(
          GetConfigurationResponse.fromJson(
            envelope.body.response!,
          ).ptzConfiguration.token,
          'PTZToken',
        );
      });

      test('GetConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GetConfigurationOptionsResponse.xml',
        );

        expect(
          GetConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurationOptions.ptzTimeout.min,
          'PT1S',
        );
      });

      test('GetConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GetConfigurationsResponse.xml',
        );

        expect(
          GetConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetPresetsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GetPresetsResponse.xml',
        );

        expect(
          GetPresetsResponse.fromJson(
            envelope.body.response!,
          ).presets.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities?.getCompatibleConfigurations,
          true,
        );
      });

      test('GetStatusResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GetStatusResponse.xml',
        );

        expect(
          GetStatusResponse.fromJson(envelope.body.response!).ptzStatus.error,
          "NO error",
        );
      });

      test('GotoHomePositionResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GotoHomePositionResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('GotoHomePositionResponse'),
          true,
        );
      });

      test('GotoPresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/GotoPresetResponse.xml',
        );

        expect(envelope.body.response!.containsKey('GotoPresetResponse'), true);
      });

      test('RelativeMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/RelativeMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('RelativeMoveResponse'),
          true,
        );
      });

      test('RemovePresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/RemovePresetResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('RemovePresetResponse'),
          true,
        );
      });

      test('SetHomePositionResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/SetHomePositionResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('SetHomePositionResponse'),
          true,
        );
      });

      test('SetPresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/SetPresetResponse.xml',
        );

        expect(
          SetPresetResponse.fromJson(envelope.body.response!).presetToken,
          '21',
        );
      });

      test('StopResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/ptz/StopResponse.xml',
        );

        expect(envelope.body.response!.containsKey('StopResponse'), true);
      });
    });

    group("IPG-8150PSS", () {
      test('AbsoluteMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/AbsoluteMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('AbsoluteMoveResponse'),
          true,
        );
      });

      test('ContinuousMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/ContinuousMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('ContinuousMoveResponse'),
          true,
        );
      });

      test('GetCompatibleConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GetCompatibleConfigurationsResponse.xml',
        );

        expect(
          GetCompatibleConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GetConfigurationOptionsResponse.xml',
        );

        expect(
          GetConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurationOptions.ptzTimeout.min,
          'PT1S',
        );
      });

      test('GetConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GetConfigurationResponse.xml',
        );

        expect(
          GetConfigurationResponse.fromJson(
            envelope.body.response!,
          ).ptzConfiguration.token,
          'PTZConfigurationToken',
        );
      });

      test('GetConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GetConfigurationsResponse.xml',
        );

        expect(
          GetConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetPresetsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GetPresetsResponse.xml',
        );

        expect(
          GetPresetsResponse.fromJson(
            envelope.body.response!,
          ).presets.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities?.getCompatibleConfigurations,
          false,
        );
      });

      test('GetStatusResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GetStatusResponse.xml',
        );

        expect(
          GetStatusResponse.fromJson(
            envelope.body.response!,
          ).ptzStatus.moveStatus?.panTilt,
          'IDLE',
        );
      });

      test('GotoHomePositionResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GotoHomePositionResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('GotoHomePositionResponse'),
          true,
        );
      });

      test('GotoPresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/GotoPresetResponse.xml',
        );

        expect(envelope.body.response!.containsKey('GotoPresetResponse'), true);
      });

      test('RelativeMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/RelativeMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('RelativeMoveResponse'),
          true,
        );
      });

      test('RemovePresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/RemovePresetResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('RemovePresetResponse'),
          true,
        );
      });

      test('SetHomePositionResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/SetHomePositionResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('SetHomePositionResponse'),
          true,
        );
      });

      test('SetPresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/SetPresetResponse.xml',
        );

        expect(
          SetPresetResponse.fromJson(envelope.body.response!).presetToken,
          'z_ovf_ptz_99',
        );
      });

      test('StopResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/ptz/StopResponse.xml',
        );

        expect(envelope.body.response!.containsKey('StopResponse'), true);
      });
    });

    group("SUNBA", () {
      test('AbsoluteMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/AbsoluteMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('AbsoluteMoveResponse'),
          true,
        );
      });

      test('ContinuousMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/ContinuousMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('ContinuousMoveResponse'),
          true,
        );
      });

      test('GetCompatibleConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/GetCompatibleConfigurationsResponse.xml',
        );

        expect(
          GetCompatibleConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/GetConfigurationOptionsResponse.xml',
        );

        expect(
          GetConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurationOptions.ptzTimeout.min,
          'PT1S',
        );
      });

      test('GetConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/GetConfigurationResponse.xml',
        );

        expect(
          GetConfigurationResponse.fromJson(
            envelope.body.response!,
          ).ptzConfiguration.token,
          'ptz_node_config1',
        );
      });

      test('GetConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/GetConfigurationsResponse.xml',
        );

        expect(
          GetConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetPresetsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/GetPresetsResponse.xml',
        );

        expect(
          GetPresetsResponse.fromJson(
            envelope.body.response!,
          ).presets.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities?.getCompatibleConfigurations,
          true,
        );
      });

      test('GetStatusResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/GetStatusResponse.xml',
        );

        expect(
          GetStatusResponse.fromJson(
            envelope.body.response!,
          ).ptzStatus.moveStatus?.panTilt,
          'IDLE',
        );
      });

      // test('GotoHomePositionResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //       '../../test_data/xml/IPG-8150PSS/ptz/GotoHomePositionResponse.xml');

      //   expect(envelope.body.response!.containsKey('GotoHomePositionResponse'),
      //       true);
      // });

      test('GotoPresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/GotoPresetResponse.xml',
        );

        expect(envelope.body.response!.containsKey('GotoPresetResponse'), true);
      });

      // test('RelativeMoveResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //     '../../test_data/xml/SUNBA/ptz/RelativeMoveResponse.xml',
      //   );

      //   expect(
      //     envelope.body.response!.containsKey('RelativeMoveResponse'),
      //     true,
      //   );
      // });

      test('RemovePresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/RemovePresetResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('RemovePresetResponse'),
          true,
        );
      });

      // test('SetHomePositionResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //       '../../test_data/xml/IPG-8150PSS/ptz/SetHomePositionResponse.xml');

      //   expect(envelope.body.response!.containsKey('SetHomePositionResponse'),
      //       true);
      // });

      test('SetPresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/SetPresetResponse.xml',
        );

        expect(
          SetPresetResponse.fromJson(envelope.body.response!).presetToken,
          '1',
        );
      });

      test('StopResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/ptz/StopResponse.xml',
        );

        expect(envelope.body.response!.containsKey('StopResponse'), true);
      });
    });

    group('IPD-H4K8M05-BS', () {
      test('AbsoluteMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/AbsoluteMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('AbsoluteMoveResponse'),
          true,
        );
      });

      test('ContinuousMoveResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/ContinuousMoveResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('ContinuousMoveResponse'),
          true,
        );
      });

      // test('GetCompatibleConfigurationsResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //     '../../test_data/xml/IPD-H4K8M05-BS/ptz/GetCompatibleConfigurationsResponse.xml',
      //   );

      //   expect(
      //     GetCompatibleConfigurationsResponse.fromJson(
      //       envelope.body.response!,
      //     ).ptzConfigurations.isNotEmpty,
      //     true,
      //   );
      // });

      test('GetConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/GetConfigurationOptionsResponse.xml',
        );

        expect(
          GetConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurationOptions.ptzTimeout.min,
          'PT3S',
        );
      });

      test('GetConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/GetConfigurationResponse.xml',
        );

        expect(
          GetConfigurationResponse.fromJson(
            envelope.body.response!,
          ).ptzConfiguration.token,
          'PTZCFG_CH0',
        );
      });

      test('GetConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/GetConfigurationsResponse.xml',
        );

        expect(
          GetConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).ptzConfigurations.isNotEmpty,
          true,
        );
      });

      test('GetPresetsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/GetPresetsResponse.xml',
        );

        expect(
          GetPresetsResponse.fromJson(
            envelope.body.response!,
          ).presets.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('GetServiceCapabilitiesResponse'),
          true,
        );
      });

      test('GetStatusResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/GetStatusResponse.xml',
        );

        expect(
          GetStatusResponse.fromJson(
            envelope.body.response!,
          ).ptzStatus.position.panTilt?.y,
          32768,
        );
      });

      // test('GotoHomePositionResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //       '../../test_data/xml/IPG-8150PSS/ptz/GotoHomePositionResponse.xml');

      //   expect(envelope.body.response!.containsKey('GotoHomePositionResponse'),
      //       true);
      // });

      // test('GotoPresetResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //     '../../test_data/xml/IPD-H4K8M05-BS/ptz/GotoPresetResponse.xml',
      //   );

      //   expect(envelope.body.response!.containsKey('GotoPresetResponse'), true);
      // });

      // test('RelativeMoveResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //     '../../test_data/xml/IPD-H4K8M05-BS/ptz/RelativeMoveResponse.xml',
      //   );

      //   expect(
      //     envelope.body.response!.containsKey('RelativeMoveResponse'),
      //     true,
      //   );
      // });

      // test('RemovePresetResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //     '../../test_data/xml/IPD-H4K8M05-BS/ptz/RemovePresetResponse.xml',
      //   );

      //   expect(
      //     envelope.body.response!.containsKey('RemovePresetResponse'),
      //     true,
      //   );
      // });

      // test('SetHomePositionResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //       '../../test_data/xml/IPG-8150PSS/ptz/SetHomePositionResponse.xml');

      //   expect(envelope.body.response!.containsKey('SetHomePositionResponse'),
      //       true);
      // });

      test('SetPresetResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/SetPresetResponse.xml',
        );

        expect(
          SetPresetResponse.fromJson(envelope.body.response!).presetToken,
          '2',
        );
      });

      test('StopResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/ptz/StopResponse.xml',
        );

        expect(envelope.body.response!.containsKey('StopResponse'), true);
      });
    });
  });
}
