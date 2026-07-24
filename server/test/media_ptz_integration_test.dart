import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

/// End-to-end verification of Milestone 2: the real `easy_onvif` client
/// exercises the Media (profiles / stream / snapshot) and PTZ services.
void main() {
  const port = 8092;

  late OnvifDevice device;

  setUp(() async {
    device = OnvifDevice(
      config: const ServerConfig(httpPort: port),
      hardware: StubHardwareAdapter(),
      streamBackend: StubStreamBackend(
        urlFor: (host, profile) => 'rtsp://$host:8554/onvif/$profile',
      ),
    );

    await device.start();
  });

  tearDown(() async {
    await device.stop();
  });

  Future<Onvif> connect() => Onvif.connect(
    host: 'localhost:$port',
    username: 'admin',
    password: 'admin',
  );

  test('client lists media profiles', () async {
    final onvif = await connect();

    final profiles = await onvif.media.getProfiles();

    expect(profiles, isNotEmpty);
    expect(profiles.first.token, 'Profile_1');
  });

  test('client retrieves a stream URI', () async {
    final onvif = await connect();

    final profiles = await onvif.media.getProfiles();
    final streamUri = await onvif.media.getStreamUri(profiles.first.token);

    expect(streamUri, startsWith('rtsp://'));
    expect(streamUri, contains('Profile_1'));
  });

  test('client retrieves a snapshot URI', () async {
    final onvif = await connect();

    final profiles = await onvif.media.getProfiles();
    final snapshotUri = await onvif.media.getSnapshotUri(profiles.first.token);

    expect(snapshotUri, startsWith('http://'));
    expect(snapshotUri, contains('/onvif/snapshot/Profile_1'));
  });

  test('client reads PTZ configurations and status', () async {
    final onvif = await connect();

    final configurations = await onvif.ptz.getConfigurations();

    expect(configurations, isNotEmpty);
    expect(configurations.first.token, 'PTZConfig_1');

    final profiles = await onvif.media.getProfiles();
    final status = await onvif.ptz.getStatus(profiles.first.token);

    expect(status.position.panTilt, isNotNull);
    expect(status.position.panTilt!.x, 0.0);
  });

  test(
    'client performs an absolute move and reads back the position',
    () async {
      final onvif = await connect();

      final profiles = await onvif.media.getProfiles();
      final profileToken = profiles.first.token;

      final moved = await onvif.ptz.absoluteMove(
        profileToken,
        position: PtzVector(
          panTilt: Vector2D(x: 0.5, y: -0.25),
          zoom: Vector1D(x: 0.75),
        ),
      );

      expect(moved, isTrue);

      final status = await onvif.ptz.getStatus(profileToken);

      expect(status.position.panTilt!.x, closeTo(0.5, 0.001));
      expect(status.position.panTilt!.y, closeTo(-0.25, 0.001));
      expect(status.position.zoom!.x, closeTo(0.75, 0.001));
    },
  );

  test('client sets, lists and recalls a preset', () async {
    final onvif = await connect();

    final profiles = await onvif.media.getProfiles();
    final profileToken = profiles.first.token;

    await onvif.ptz.absoluteMove(
      profileToken,
      position: PtzVector(
        panTilt: Vector2D(x: 0.1, y: 0.2),
        zoom: Vector1D(x: 0.3),
      ),
    );

    final presetToken = await onvif.ptz.setPreset(
      profileToken,
      presetName: 'Test Preset',
    );

    expect(presetToken, isNotEmpty);

    // Add a second preset. The client's GetPresetsResponse parser expects the
    // `Preset` element to deserialize as a list, which `xml2json` only
    // produces when two or more presets are present.
    await onvif.ptz.absoluteMove(
      profileToken,
      position: PtzVector(
        panTilt: Vector2D(x: -0.4, y: 0.6),
        zoom: Vector1D(x: 0.1),
      ),
    );

    await onvif.ptz.setPreset(profileToken, presetName: 'Second Preset');

    final presets = await onvif.ptz.getPresets(profileToken);

    expect(presets.map((p) => p.token), contains(presetToken));
    expect(
      presets.firstWhere((p) => p.token == presetToken).name,
      'Test Preset',
    );

    // Move away, then recall the preset and confirm the position is restored.
    await onvif.ptz.absoluteMove(
      profileToken,
      position: PtzVector(
        panTilt: Vector2D(x: 0.9, y: 0.9),
        zoom: Vector1D(x: 0.9),
      ),
    );

    final recalled = await onvif.ptz.gotoPreset(
      profileToken,
      presetToken: presetToken,
    );

    expect(recalled, isTrue);

    final status = await onvif.ptz.getStatus(profileToken);

    expect(status.position.panTilt!.x, closeTo(0.1, 0.001));
    expect(status.position.panTilt!.y, closeTo(0.2, 0.001));
    expect(status.position.zoom!.x, closeTo(0.3, 0.001));
  });
}
