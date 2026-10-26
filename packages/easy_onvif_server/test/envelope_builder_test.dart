import 'package:easy_onvif/device_management.dart';
import 'package:easy_onvif/soap.dart' show Envelope, Xmlns;
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/soap/envelope_builder.dart';

void main() {
  test(
    'GetDeviceInformationResponse round-trips through the client parser',
    () {
      final xml = SoapEnvelopeBuilder.response((builder) {
        builder.element(
          'GetDeviceInformationResponse',
          namespaceUri: Xmlns.tds,
          nest: () {
            builder.element(
              'Manufacturer',
              namespaceUri: Xmlns.tds,
              nest: 'easy_onvif',
            );
            builder.element(
              'Model',
              namespaceUri: Xmlns.tds,
              nest: 'Dart ONVIF Server',
            );
            builder.element(
              'FirmwareVersion',
              namespaceUri: Xmlns.tds,
              nest: '0.1.0',
            );
            builder.element(
              'SerialNumber',
              namespaceUri: Xmlns.tds,
              nest: 'SN-0001',
            );
            builder.element('HardwareId', namespaceUri: Xmlns.tds, nest: '1');
          },
        );
      });

      // ignore: avoid_print
      print(xml);

      final envelope = Envelope.fromXmlString(xml);

      expect(envelope.body.hasFault, isFalse);

      final info = GetDeviceInformationResponse.fromJson(
        envelope.body.response!,
      );

      expect(info.manufacturer, 'easy_onvif');
      expect(info.model, 'Dart ONVIF Server');
      expect(info.firmwareVersion, '0.1.0');
      expect(info.serialNumber, 'SN-0001');
      expect(info.hardwareId, '1');
    },
  );

  test('fault envelope is detected by the client parser', () {
    final xml = SoapEnvelopeBuilder.fault(
      subcode: 'NotAuthorized',
      reason: 'The credentials supplied were invalid.',
    );

    // ignore: avoid_print
    print(xml);

    final envelope = Envelope.fromXmlString(xml);

    expect(envelope.body.hasFault, isTrue);
    expect(
      envelope.body.fault!.reason!.note,
      'The credentials supplied were invalid.',
    );
  });
}
