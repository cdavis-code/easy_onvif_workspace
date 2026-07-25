/// G.711 A-law compression (ITU-T G.711), ported from the classic Sun
/// `g711.c` reference implementation.
///
/// The RTSP audio track and the recording sidecars both carry raw A-law
/// bytes, so this is the single encode step between native PCM capture and
/// the wire/disk formats.
library;

import 'dart:typed_data';

const _segmentEnds = [0x1F, 0x3F, 0x7F, 0xFF, 0x1FF, 0x3FF, 0x7FF, 0xFFF];

/// Encodes one signed 16-bit PCM sample to an 8-bit A-law byte.
int alawEncodeSample(int pcm) {
  var value = pcm >> 3; // 16-bit to the 13-bit range A-law is defined over.

  int mask;

  if (value >= 0) {
    mask = 0xD5; // Sign bit set (positive), with the A-law toggle pattern.
  } else {
    mask = 0x55;
    value = -value - 1;
  }

  var segment = 0;

  while (segment < 8 && value > _segmentEnds[segment]) {
    segment++;
  }

  if (segment >= 8) return 0x7F ^ mask;

  var alaw = segment << 4;

  alaw |= segment < 2 ? (value >> 1) & 0x0f : (value >> segment) & 0x0f;

  return alaw ^ mask;
}

/// Encodes a PCM16 buffer to A-law, one byte per sample.
Uint8List alawEncode(Int16List pcm) {
  final out = Uint8List(pcm.length);

  for (var i = 0; i < pcm.length; i++) {
    out[i] = alawEncodeSample(pcm[i]);
  }

  return out;
}
