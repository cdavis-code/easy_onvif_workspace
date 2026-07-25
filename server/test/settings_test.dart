import 'package:easy_onvif/onvif.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

void main() {
  test('defaults apply when yaml is empty', () {
    final settings = ServerSettings.parse('');

    expect(settings.config.httpPort, 8080);
    expect(settings.config.rtspPort, 8554);
    expect(settings.config.username, 'admin');
    expect(settings.config.manufacturer, 'easy_onvif');
    expect(settings.services.recording, isTrue);
    expect(settings.services.replay, isTrue);
    expect(settings.services.search, isTrue);
    expect(settings.services.imaging, isTrue);
    expect(settings.segmentSeconds, 10);
    expect(settings.maxRetentionMinutes, isNull);
    expect(settings.recordingDirectory, isNull);
    expect(settings.imagingPresets, isNotEmpty);
    expect(settings.geoFallback, isNull);
  });

  test('yaml values override defaults', () {
    const yaml = '''
device:
  manufacturer: Acme
  model: SimCam 9000
  firmware: 9.9.9
  serial: SN-1234
  hardwareId: hw-77
  hostname: acme-cam
network:
  httpPort: 9080
  rtspPort: 9554
auth:
  username: operator
  password: secret
services:
  recording: false
  imaging: false
recording:
  directory: /tmp/onvif_recordings
  segmentSeconds: 4
  maxRetentionMinutes: 30
imaging:
  presets:
    - token: night
      name: Night Mode
      type: NightMode
geolocation:
  lat: 43.65
  lon: -79.38
  elevation: 76.0
''';

    final settings = ServerSettings.parse(yaml);

    expect(settings.config.manufacturer, 'Acme');
    expect(settings.config.model, 'SimCam 9000');
    expect(settings.config.firmwareVersion, '9.9.9');
    expect(settings.config.serialNumber, 'SN-1234');
    expect(settings.config.hardwareId, 'hw-77');
    expect(settings.config.hostname, 'acme-cam');
    expect(settings.config.httpPort, 9080);
    expect(settings.config.rtspPort, 9554);
    expect(settings.config.username, 'operator');
    expect(settings.config.password, 'secret');
    expect(settings.services.recording, isFalse);
    expect(settings.services.replay, isTrue);
    expect(settings.services.imaging, isFalse);
    expect(settings.recordingDirectory, '/tmp/onvif_recordings');
    expect(settings.segmentSeconds, 4);
    expect(settings.maxRetentionMinutes, 30);
    expect(settings.imagingPresets.single.token, 'night');
    expect(settings.imagingPresets.single.name, 'Night Mode');
    expect(settings.imagingPresets.single.type, 'NightMode');
    expect(settings.geoFallback!.latitude, 43.65);
    expect(settings.geoFallback!.longitude, -79.38);
    expect(settings.geoFallback!.elevation, 76.0);
  });

  test('quoted scalars coerce instead of crashing', () {
    const yaml = '''
network:
  httpPort: "9080"
services:
  recording: "false"
geolocation:
  lat: "43.65"
  lon: "-79.38"
''';

    final settings = ServerSettings.parse(yaml);

    expect(settings.config.httpPort, 9080);
    expect(settings.services.recording, isFalse);
    expect(settings.geoFallback!.latitude, 43.65);
  });

  test('non-numeric port throws FormatException', () {
    expect(
      () => ServerSettings.parse('network:\n  httpPort: not-a-port\n'),
      throwsA(isA<FormatException>()),
    );
  });

  test('malformed yaml throws FormatException', () {
    expect(
      () => ServerSettings.parse(': not yaml : ['),
      throwsA(isA<FormatException>()),
    );
  });

  group('service flags', () {
    test('disabled services are not advertised and fault when called', () async {
      const config = ServerConfig(httpPort: 8100, rtspPort: 8566);

      final device = OnvifDevice(
        config: config,
        hardware: StubHardwareAdapter(),
        streamBackend: StubStreamBackend(urlFor: config.rtspUrl),
        settings: ServerSettings.parse('''
services:
  recording: false
  replay: false
  search: false
  imaging: false
''', base: config),
      );

      await device.start();
      addTearDown(device.stop);

      final onvif = await Onvif.connect(
        host: 'localhost:8095',
        username: 'admin',
        password: 'admin',
      );

      final services = await onvif.deviceManagement.getServices();
      final namespaces = services.map((s) => s.nameSpace).toList();

      expect(
        namespaces,
        isNot(contains('http://www.onvif.org/ver10/recording/wsdl')),
      );
      expect(
        namespaces,
        isNot(contains('http://www.onvif.org/ver10/search/wsdl')),
      );
      expect(
        namespaces,
        isNot(contains('http://www.onvif.org/ver10/replay/wsdl')),
      );
      expect(
        namespaces,
        isNot(contains('http://www.onvif.org/ver20/imaging/wsdl')),
      );
      expect(namespaces, contains('http://www.onvif.org/ver10/device/wsdl'));

      // Client getters throw when the service was not advertised.
      expect(() => onvif.recordings, throwsException);
    });

    test('enabled services are advertised by default', () async {
      const config = ServerConfig(httpPort: 8101, rtspPort: 8567);

      final device = OnvifDevice(
        config: config,
        hardware: StubHardwareAdapter(),
        streamBackend: StubStreamBackend(urlFor: config.rtspUrl),
        settings: ServerSettings.parse('', base: config),
      );

      await device.start();
      addTearDown(device.stop);

      final onvif = await Onvif.connect(
        host: 'localhost:8094',
        username: 'admin',
        password: 'admin',
      );

      final services = await onvif.deviceManagement.getServices();
      final namespaces = services.map((s) => s.nameSpace).toList();

      expect(namespaces, contains('http://www.onvif.org/ver10/recording/wsdl'));
      expect(namespaces, contains('http://www.onvif.org/ver10/search/wsdl'));
      expect(namespaces, contains('http://www.onvif.org/ver10/replay/wsdl'));
      expect(namespaces, contains('http://www.onvif.org/ver20/imaging/wsdl'));
    });
  });
}
