import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/streaming/audio_source.dart';
import 'package:easy_onvif_server/src/streaming/ffmpeg_audio_source.dart';
import 'package:easy_onvif_server/src/streaming/native_audio_source.dart';

void main() {
  test('AlawFramer chunks a byte stream into timestamped 20 ms frames', () {
    final frames = <AudioFrame>[];
    final framer = AlawFramer(frames.add);

    framer.add(List.filled(100, 1)); // Not enough for a frame yet.
    expect(frames, isEmpty);

    framer.add(List.filled(300, 2)); // 400 buffered => 2 frames + 80 left.
    expect(frames, hasLength(2));
    expect(frames[0].data, hasLength(160));
    expect(frames[0].timestamp, 0);
    expect(frames[1].timestamp, 160);

    framer.add(List.filled(80, 3)); // Completes the third frame exactly.
    expect(frames, hasLength(3));
    expect(frames[2].timestamp, 320);
  });

  test('FfmpegAudioSource produces real-time A-law frames', () async {
    final source = FfmpegAudioSource(); // Default input: lavfi sine.
    final frames = <AudioFrame>[];
    final subscription = source.frames.listen(frames.add);

    await source.start();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await source.stop();
    await subscription.cancel();

    // ~75 frames in 1.5 s; accept generous margins for process spin-up.
    expect(frames.length, greaterThan(30));
    expect(frames.every((f) => f.data.length == 160), isTrue);
    expect(frames[1].timestamp - frames[0].timestamp, 160);
  });

  test('NativeAudioSource converts PCM16 chunks into A-law frames', () async {
    final source = NativeAudioSource();
    final frames = <AudioFrame>[];
    final subscription = source.frames.listen(frames.add);

    // 320 zero samples = 640 bytes PCM16 = two 20 ms frames of A-law 0xD5.
    source.addPcmBytes(Uint8List(640));

    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(frames, hasLength(2));
    expect(frames.first.data.every((byte) => byte == 0xD5), isTrue);
    expect(frames[1].timestamp, 160);
  });

  test(
    'NativeAudioSource tolerates odd-offset platform channel views',
    () async {
      // The standard message codec returns views into the shared message
      // buffer, which can start at an odd byte offset (regression: RangeError
      // from Int16List.view's alignment check).
      final backing = Uint8List(1 + 640); // 1-byte header, then the PCM chunk.
      final chunk = Uint8List.view(backing.buffer, 1, 640);

      expect(chunk.offsetInBytes.isOdd, isTrue);

      final source = NativeAudioSource();
      final frames = <AudioFrame>[];
      final subscription = source.frames.listen(frames.add);

      source.addPcmBytes(chunk);

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(frames, hasLength(2));
      expect(frames.first.data.every((byte) => byte == 0xD5), isTrue);
    },
  );
}
