import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/streaming/alaw.dart';

void main() {
  test('encodes ITU reference samples', () {
    // Classic G.711 A-law reference points (Sun g711.c behavior).
    expect(alawEncodeSample(0), 0xD5);
    expect(alawEncodeSample(-1), 0x55);
    expect(alawEncodeSample(32767), 0xAA);
    expect(alawEncodeSample(-32768), 0x2A);
  });

  test('positive and negative values differ only in the sign bit', () {
    for (final value in [8, 100, 1000, 5000, 20000]) {
      expect(
        alawEncodeSample(-value - 1),
        alawEncodeSample(value) ^ 0x80,
        reason: 'value $value',
      );
    }
  });

  test('encodes a buffer sample-for-sample', () {
    final pcm = Int16List.fromList([0, -1, 32767, -32768]);

    expect(alawEncode(pcm), Uint8List.fromList([0xD5, 0x55, 0xAA, 0x2A]));
  });
}
