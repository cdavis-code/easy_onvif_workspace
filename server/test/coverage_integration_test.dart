import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/soap.dart' as soap;
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

/// Coverage tests for the operations that fill the remaining gaps against the
/// `easy_onvif` README's "Supported Onvif Operations" matrix (device
/// management here; media and imaging groups are added by later tasks).
void main() {
  const httpPort = 8096;
  const config = ServerConfig(httpPort: httpPort, rtspPort: 8562);

  late OnvifDevice device;
  late Onvif onvif;

  setUpAll(() async {
    device = OnvifDevice(
      config: config,
      hardware: StubHardwareAdapter(),
      streamBackend: StubStreamBackend(urlFor: config.rtspUrl),
    );

    await device.start();

    onvif = await Onvif.connect(
      host: 'localhost:$httpPort',
      username: 'admin',
      password: 'admin',
    );
  });

  tearDownAll(() => device.stop());

  group('device management gaps', () {
    test('getSystemLog returns recent log lines', () async {
      final log = await onvif.deviceManagement.getSystemLog('System');

      // The startup banner is always logged before the test runs, so the
      // buffer must contain real content rather than the empty fallback.
      expect(log.string, contains('ONVIF server listening'));
      expect(log.string, isNot(contains('No System log entries recorded.')));
    });

    test('getSystemSupportInformation returns platform info', () async {
      final info = await onvif.deviceManagement.getSystemSupportInformation();

      expect(info?.string, contains('OS:'));
    });

    test('getEndpointReference returns the device uuid', () async {
      // The client helper is commented out upstream; use a low-level request.
      soap.Transport.builder.element('GetEndpointReference', nest: () {
        soap.Transport.builder.namespace(soap.Xmlns.tds);
      });

      final envelope = await onvif.deviceManagement.transport.securedRequest(
        onvif.deviceManagement.uri,
        soap.Body(request: soap.Transport.builder.buildFragment()),
      );

      expect(envelope.body.response.toString(), contains(config.endpointUuid));
    });

    test('getIPAddressFilter returns an empty Allow filter', () async {
      final filter = await onvif.deviceManagement.getIPAddressFilter();

      expect(filter.type.name, 'allow');
      expect(filter.prefixedIpv4Addresses, isEmpty);
    });

    test('storage configurations report the recording directory', () async {
      final configs = await onvif.deviceManagement.getStorageConfigurations();

      expect(configs, hasLength(1));
      expect(configs.first.data.type, 'Local');
      expect(configs.first.data.localPath, isNotNull);
      expect(configs.first.data.localPath, isNotEmpty);

      final single = await onvif.deviceManagement.getStorageConfiguration(
        configs.first.token,
      );

      expect(single.data.type, 'Local');
      expect(single.data.localPath, configs.first.data.localPath);

      await expectLater(
        onvif.deviceManagement.getStorageConfiguration('BogusToken'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('media gaps', () {
    test('media1 getMetadataConfiguration', () async {
      final mc = await onvif.media.media1.getMetadataConfiguration(
        'MetadataConfig_1',
      );

      expect(mc?.token, 'MetadataConfig_1');
      expect(mc?.name, isNotEmpty);
    });

    test('media2 getVideoEncoderConfigurations', () async {
      // Not exposed by the client Media2 facade; use a low-level request.
      soap.Transport.builder.element(
        'GetVideoEncoderConfigurations',
        nest: () {
          soap.Transport.builder.namespace(soap.Xmlns.tr2);
        },
      );

      final envelope = await onvif.media.media2.transport.securedRequest(
        onvif.media.media2.uri,
        soap.Body(request: soap.Transport.builder.buildFragment()),
      );

      expect(envelope.body.response?['Configurations'], isNotNull);
    });

    test('media2 getVideoEncoderInstances', () async {
      final info = await onvif.media.media2.getVideoEncoderInstances(
        'VideoEncoderConfig_1',
      );

      expect(info.total, greaterThanOrEqualTo(1));
    });

    test('media2 getVideoSourceConfigurationOptions', () async {
      final options = await onvif.media.media2
          .getVideoSourceConfigurationOptions();

      expect(options.videoSourceTokensAvailable, contains('VideoSource_1'));
      expect(options.boundsRange.widthRange.max, greaterThan(0));
    });

    test('media2 getMetadataConfigurationOptions', () async {
      final options = await onvif.media.media2
          .getMetadataConfigurationOptions();

      expect(options.ptzStatusFilterOptions, isNotNull);
    });
  });
}
