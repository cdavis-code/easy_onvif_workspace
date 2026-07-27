import 'package:easy_onvif/media2.dart';
import 'package:easy_onvif/onvif.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/hardware/hardware_adapter.dart';
import 'package:easy_onvif_server/src/onvif_device.dart';
import 'package:easy_onvif_server/src/streaming/stream_backend.dart';

/// Integration tests for the Media2 WebRTC configuration operations
/// (`GetWebRTCConfigurations` / `SetWebRTCConfigurations`). The server
/// reflects its own built-in `/onvif/webrtc` signaling endpoint rather than
/// connecting to an external signaling server.
void main() {
  const httpPort = 8110;
  const config = ServerConfig(httpPort: httpPort, rtspPort: 8570);

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

  group('Media2 WebRTC configuration', () {
    test('getWebRTCConfigurations reflects the built-in endpoint', () async {
      final configurations = await onvif.media.media2.getWebRTCConfigurations();

      expect(configurations, hasLength(1));

      final configuration = configurations.single;
      expect(
        configuration.signalingServer,
        'ws://localhost:$httpPort/onvif/webrtc',
      );
      expect(configuration.authorizationServer, 'AuthorizationServer_1');
      expect(configuration.defaultProfile, 'Profile_1');
      expect(configuration.enabled, isTrue);
      expect(configuration.connected, isFalse);
    });

    test('setWebRTCConfigurations round-trips the mutable fields', () async {
      final updated = await onvif.media.media2.setWebRTCConfigurations([
        WebrtcConfiguration(
          signalingServer: 'ws://ignored:1/onvif/webrtc',
          authorizationServer: 'AuthorizationServer_1',
          defaultProfile: 'Profile_2',
          enabled: false,
        ),
      ]);

      expect(updated, isTrue);

      final configuration =
          (await onvif.media.media2.getWebRTCConfigurations()).single;

      // The mutable fields round-trip...
      expect(configuration.defaultProfile, 'Profile_2');
      expect(configuration.enabled, isFalse);

      // ...but the signaling server always reflects the built-in endpoint.
      expect(
        configuration.signalingServer,
        'ws://localhost:$httpPort/onvif/webrtc',
      );
    });
  });
}
