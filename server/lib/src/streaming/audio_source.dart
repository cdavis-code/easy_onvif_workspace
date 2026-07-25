import 'dart:async';
import 'dart:typed_data';

/// One 20 ms G.711 A-law audio frame: 160 bytes at 8 kHz mono.
class AudioFrame {
  /// Raw A-law payload (exactly [AlawFramer.frameBytes] bytes).
  final Uint8List data;

  /// 8 kHz RTP timestamp; advances by 160 per frame.
  final int timestamp;

  AudioFrame(this.data, this.timestamp);
}

/// A source of G.711 A-law frames that the RTSP server can serve as an audio
/// track and the segment recorder can persist. Mirrors `NalStreamSource`.
abstract interface class AudioStreamSource {
  /// The live stream of 20 ms frames (a broadcast stream).
  Stream<AudioFrame> get frames;

  Future<void> start();

  Future<void> stop();
}

/// Chunks a continuous A-law byte stream into timestamped 20 ms [AudioFrame]s.
class AlawFramer {
  /// 20 ms at 8000 samples/s, one byte per sample.
  static const frameBytes = 160;

  final void Function(AudioFrame frame) onFrame;

  final List<int> _buffer = [];

  int _timestamp = 0;

  AlawFramer(this.onFrame);

  void add(List<int> data) {
    _buffer.addAll(data);

    while (_buffer.length >= frameBytes) {
      onFrame(
        AudioFrame(
          Uint8List.fromList(_buffer.sublist(0, frameBytes)),
          _timestamp,
        ),
      );

      _buffer.removeRange(0, frameBytes);

      _timestamp = (_timestamp + frameBytes) & 0xffffffff;
    }
  }
}
