import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_audio_source.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_backend.dart';
import 'package:easy_onvif_server/src/streaming/h264_source.dart';
import 'package:easy_onvif_server/src/streaming/rtsp_server.dart';

/// A parameter-set-only stub so buildSdp can run without live media.
class _StubNals implements NalStreamSource {
  @override
  Stream<H264NalUnit> get nals => const Stream.empty();

  @override
  Uint8List? get sps => Uint8List.fromList([0x67, 0x42, 0xC0, 0x1E]);

  @override
  Uint8List? get pps => Uint8List.fromList([0x68, 0xCE, 0x38, 0x80]);

  @override
  Future<void> get parametersReady => Future.value();
}

void main() {
  test('SDP advertises the audio track only when audio is attached', () {
    final server = RtspServer(source: _StubNals(), port: 0);

    final without = server.buildSdp(_StubNals(), hasAudio: false);
    expect(without, isNot(contains('m=audio')));

    final withAudio = server.buildSdp(_StubNals(), hasAudio: true);
    expect(withAudio, contains('m=audio 0 RTP/AVP 8'));
    expect(withAudio, contains('a=rtpmap:8 PCMA/8000'));
    expect(withAudio, contains('a=control:trackID=1'));
  });

  test(
    'RTSP stream carries both h264 and pcm_alaw',
    () async {
      const config = ServerConfig(httpPort: 8104, rtspPort: 8566);

      final backend = FfmpegBackend(
        config: config,
        frameRate: 15,
        inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
        audioSource: FfmpegAudioSource(),
      );

      await backend.start('Profile_1', host: 'localhost');

      try {
        final result = await Process.run('ffprobe', [
          '-v',
          'error',
          '-rtsp_transport',
          'tcp',
          '-show_entries',
          'stream=codec_name',
          '-of',
          'csv=p=0',
          'rtsp://admin:admin@127.0.0.1:8566/onvif/Profile_1',
        ]);

        expect(result.stdout.toString(), contains('h264'));
        expect(result.stdout.toString(), contains('pcm_alaw'));
      } finally {
        await backend.stop();
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'rejects an unauthenticated RTSP request with 401',
    () async {
      const config = ServerConfig(httpPort: 8108, rtspPort: 8568);

      final backend = FfmpegBackend(
        config: config,
        frameRate: 15,
        inputArgs: ['-f', 'lavfi', '-i', 'testsrc=size=640x480:rate=15'],
      );

      await backend.start('Profile_1', host: 'localhost');

      try {
        final socket = await Socket.connect('127.0.0.1', 8568);
        socket.write(
          'OPTIONS rtsp://127.0.0.1:8568/onvif/Profile_1 RTSP/1.0\r\n'
          'CSeq: 1\r\n\r\n',
        );
        await socket.flush();

        final response = StringBuffer();
        final stream = utf8.decoder
            .bind(socket)
            .timeout(
              const Duration(seconds: 3),
              onTimeout: (sink) => sink.close(),
            );

        await for (final chunk in stream) {
          response.write(chunk);
          if (response.toString().contains('\r\n\r\n')) break;
        }

        socket.destroy();

        expect(response.toString(), contains('401'));
        expect(response.toString(), contains('WWW-Authenticate'));
      } finally {
        await backend.stop();
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
