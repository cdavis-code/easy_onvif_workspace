import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/streaming/h264_source.dart';

/// A minimal IDR slice NAL: type 5, first_mb_in_slice == 0 (first bit set),
/// so the framer treats each one as the start of a new access unit.
Uint8List _idrNal() => Uint8List.fromList([0x65, 0x88, 0x84, 0x00]);

void main() {
  group('AccessUnitFramer live timestamps', () {
    test(
      'stamps access units from the wall clock, not a fixed increment',
      () async {
        var nowMicros = 0;

        final framer = AccessUnitFramer(
          frameRate: 15,
          liveTimestamps: true,
          clockMicros: () => nowMicros,
        );

        final received = <H264NalUnit>[];
        framer.nals.listen(received.add);

        // Frames arriving at 30 fps (33_333 us apart) — twice the configured
        // frame rate, as a 30 fps camera delivers against a 15 fps config.
        for (var i = 0; i < 4; i++) {
          nowMicros = i * 33333;
          framer.addNal(_idrNal());
        }
        framer.flush();

        // The broadcast stream delivers in microtasks; let them drain.
        await Future<void>.delayed(Duration.zero);

        expect(received, hasLength(4));

        // Each access unit must carry the 90 kHz equivalent of its arrival
        // time: 33_333 us → ~3_000 ticks, NOT the fixed 6_000 (90_000 / 15).
        final deltas = [
          for (var i = 1; i < received.length; i++)
            received[i].timestamp - received[i - 1].timestamp,
        ];

        for (final delta in deltas) {
          expect(delta, closeTo(3000, 10));
        }
      },
    );

    test('offline mode keeps fixed frame-rate increments (replay)', () async {
      final framer = AccessUnitFramer(frameRate: 15);

      final received = <H264NalUnit>[];
      framer.nals.listen(received.add);

      for (var i = 0; i < 3; i++) {
        framer.addNal(_idrNal());
      }
      framer.flush();

      // The broadcast stream delivers in microtasks; let them drain.
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(3));
      expect(received[1].timestamp - received[0].timestamp, 6000);
      expect(received[2].timestamp - received[1].timestamp, 6000);
    });
  });

  group('FrameRateGate', () {
    test('passes a 30 fps feed through at the target 15 fps', () {
      var nowMicros = 0;

      final gate = FrameRateGate(frameRate: 15, clockMicros: () => nowMicros);

      var kept = 0;
      for (var i = 0; i < 30; i++) {
        nowMicros = i * 33333; // 30 fps arrival
        if (gate.accept()) kept++;
      }

      // One second of 30 fps input must be thinned to the target rate.
      expect(kept, inInclusiveRange(14, 16));
    });

    test('passes an at-rate feed through untouched', () {
      var nowMicros = 0;

      final gate = FrameRateGate(frameRate: 15, clockMicros: () => nowMicros);

      var kept = 0;
      for (var i = 0; i < 15; i++) {
        nowMicros = i * 66667; // already 15 fps
        if (gate.accept()) kept++;
      }

      expect(kept, 15);
    });
  });
}
