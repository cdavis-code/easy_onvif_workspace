import 'package:easy_onvif/onvif.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

void main() {
  test('defaults apply when json is empty', () {
    final settings = ServerSettings.fromJson(const {});

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

  test('json values override defaults', () {
    const json = {
      'device': {
        'manufacturer': 'Acme',
        'model': 'SimCam 9000',
        'firmware': '9.9.9',
        'serial': 'SN-1234',
        'hardwareId': 'hw-77',
        'hostname': 'acme-cam',
      },
      'network': {'httpPort': 9080, 'rtspPort': 9554},
      'auth': {'username': 'operator', 'password': 'secret'},
      'services': {'recording': false, 'imaging': false},
      'recording': {
        'directory': '/tmp/onvif_recordings',
        'segmentSeconds': 4,
        'maxRetentionMinutes': 30,
      },
      'imaging': {
        'presets': [
          {'token': 'night', 'name': 'Night Mode', 'type': 'NightMode'},
        ],
      },
      'geolocation': {'lat': 43.65, 'lon': -79.38, 'elevation': 76.0},
    };

    final settings = ServerSettings.fromJson(json);

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

  test('toJson/fromJson round-trips every section', () {
    const original = ServerSettings(
      config: ServerConfig(
        httpPort: 9080,
        rtspPort: 9554,
        username: 'operator',
        password: 'secret',
        manufacturer: 'Acme',
        model: 'SimCam 9000',
        firmwareVersion: '9.9.9',
        serialNumber: 'SN-1234',
        hardwareId: 'hw-77',
        hostname: 'acme-cam',
      ),
      services: ServiceFlags(recording: false, imaging: false),
      recordingDirectory: '/tmp/onvif_recordings',
      segmentSeconds: 4,
      maxRetentionMinutes: 30,
      imagingPresets: [
        ImagingPresetSetting(
          token: 'night',
          name: 'Night Mode',
          type: 'NightMode',
        ),
      ],
      geoFallback: GeoLocation(
        latitude: 43.65,
        longitude: -79.38,
        elevation: 76.0,
      ),
      media: MediaSettings(
        videoSource: VideoSourceKind.display,
        videoDevice: '1',
        audioEnabled: true,
        audioDevice: 'BuiltInMicrophoneDevice',
      ),
    );

    final restored = ServerSettings.fromJson(original.toJson());

    expect(restored.config.httpPort, original.config.httpPort);
    expect(restored.config.rtspPort, original.config.rtspPort);
    expect(restored.config.username, original.config.username);
    expect(restored.config.password, original.config.password);
    expect(restored.config.manufacturer, original.config.manufacturer);
    expect(restored.config.model, original.config.model);
    expect(restored.config.firmwareVersion, original.config.firmwareVersion);
    expect(restored.config.serialNumber, original.config.serialNumber);
    expect(restored.config.hardwareId, original.config.hardwareId);
    expect(restored.config.hostname, original.config.hostname);
    expect(restored.services.recording, isFalse);
    expect(restored.services.replay, isTrue);
    expect(restored.services.search, isTrue);
    expect(restored.services.imaging, isFalse);
    expect(restored.recordingDirectory, original.recordingDirectory);
    expect(restored.segmentSeconds, original.segmentSeconds);
    expect(restored.maxRetentionMinutes, original.maxRetentionMinutes);
    expect(restored.imagingPresets.single.token, 'night');
    expect(restored.geoFallback!.latitude, 43.65);
    expect(restored.geoFallback!.longitude, -79.38);
    expect(restored.geoFallback!.elevation, 76.0);
    expect(restored.media.videoSource, VideoSourceKind.display);
    expect(restored.media.videoDevice, '1');
    expect(restored.media.audioEnabled, isTrue);
    expect(restored.media.audioDevice, 'BuiltInMicrophoneDevice');
  });

  test('round-trip preserves nullable fields left unset', () {
    const original = ServerSettings();

    final restored = ServerSettings.fromJson(original.toJson());

    expect(restored.recordingDirectory, isNull);
    expect(restored.maxRetentionMinutes, isNull);
    expect(restored.geoFallback, isNull);
    expect(restored.media.audioEnabled, isFalse);
  });

  test('quoted scalars coerce instead of crashing', () {
    const json = {
      'network': {'httpPort': '9080'},
      'services': {'recording': 'false'},
      'geolocation': {'lat': '43.65', 'lon': '-79.38'},
    };

    final settings = ServerSettings.fromJson(json);

    expect(settings.config.httpPort, 9080);
    expect(settings.services.recording, isFalse);
    expect(settings.geoFallback!.latitude, 43.65);
  });

  test('unknown keys are ignored', () {
    final settings = ServerSettings.fromJson(const {
      'unknown': {'key': 'value'},
      'network': {'httpPort': 9080, 'bogus': true},
    });

    expect(settings.config.httpPort, 9080);
  });

  test('non-numeric port throws FormatException', () {
    expect(
      () => ServerSettings.fromJson(const {
        'network': {'httpPort': 'not-a-port'},
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('copyWith supports clearing nullable fields', () {
    const settings = ServerSettings(
      recordingDirectory: '/tmp/recordings',
      maxRetentionMinutes: 30,
      geoFallback: GeoLocation(latitude: 1, longitude: 2),
    );

    final cleared = settings.copyWith(
      recordingDirectory: null,
      maxRetentionMinutes: null,
      geoFallback: null,
    );
    final untouched = settings.copyWith(segmentSeconds: 5);

    expect(cleared.recordingDirectory, isNull);
    expect(cleared.maxRetentionMinutes, isNull);
    expect(cleared.geoFallback, isNull);
    expect(untouched.recordingDirectory, '/tmp/recordings');
    expect(untouched.maxRetentionMinutes, 30);
    expect(untouched.geoFallback, isNotNull);
    expect(untouched.segmentSeconds, 5);
  });

  group('service flags', () {
    test(
      'disabled services are not advertised and fault when called',
      () async {
        const config = ServerConfig(httpPort: 8100, rtspPort: 8566);

        final device = OnvifDevice(
          config: config,
          hardware: StubHardwareAdapter(),
          streamBackend: StubStreamBackend(urlFor: config.rtspUrl),
          settings: const ServerSettings(
            config: config,
            services: ServiceFlags(
              recording: false,
              replay: false,
              search: false,
              imaging: false,
            ),
          ),
        );

        await device.start();
        addTearDown(device.stop);

        final onvif = await Onvif.connect(
          host: 'localhost:8100',
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
      },
    );

    test('enabled services are advertised by default', () async {
      const config = ServerConfig(httpPort: 8101, rtspPort: 8567);

      final device = OnvifDevice(
        config: config,
        hardware: StubHardwareAdapter(),
        streamBackend: StubStreamBackend(urlFor: config.rtspUrl),
        settings: const ServerSettings(config: config),
      );

      await device.start();
      addTearDown(device.stop);

      final onvif = await Onvif.connect(
        host: 'localhost:8101',
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

  group('media settings', () {
    test('defaults to camera video and disabled audio', () {
      final settings = ServerSettings.fromJson(const {});

      expect(settings.media.videoSource, VideoSourceKind.camera);
      expect(settings.media.videoDevice, isEmpty);
      expect(settings.media.audioEnabled, isFalse);
      expect(settings.media.audioDevice, isEmpty);
    });

    test('parses the media section', () {
      final settings = ServerSettings.fromJson(const {
        'media': {
          'video': {'source': 'display', 'device': '1'},
          'audio': {'enabled': true, 'device': 'BuiltInMicrophoneDevice'},
        },
      });

      expect(settings.media.videoSource, VideoSourceKind.display);
      expect(settings.media.videoDevice, '1');
      expect(settings.media.audioEnabled, isTrue);
      expect(settings.media.audioDevice, 'BuiltInMicrophoneDevice');
    });

    test('rejects an unknown video source', () {
      expect(
        () => ServerSettings.fromJson(const {
          'media': {
            'video': {'source': 'hologram'},
          },
        }),
        throwsFormatException,
      );
    });
  });
}
