import 'dart:math' as math;
import 'dart:typed_data';

import 'h264_source.dart';

/// Packetizes H.264 NAL units into RTP packets per RFC 6184
/// (packetization-mode 1: single NAL unit and FU-A fragmentation).
class RtpPacketizer {
  final int payloadType;
  final int ssrc;
  final int maxPayload;

  int _sequence = 0;

  RtpPacketizer({this.payloadType = 96, int? ssrc, this.maxPayload = 1400})
    : ssrc = ssrc ?? math.Random().nextInt(0x7fffffff);

  /// Returns the RTP packets carrying [nal]. The RTP marker bit is set on the
  /// final packet of the access unit.
  List<Uint8List> packetize(H264NalUnit nal) {
    final data = nal.data;

    if (data.isEmpty) return const [];

    if (data.length <= maxPayload) {
      return [
        _buildRtp(data, marker: nal.lastOfFrame, timestamp: nal.timestamp),
      ];
    }

    return _fragment(data, nal);
  }

  /// Builds a single RTP packet around an opaque [payload] (e.g. one G.711
  /// audio frame). The marker defaults to unset: RFC 3551 reserves it for the
  /// start of a talkspurt, not every packet of continuous audio.
  Uint8List packetizeRaw(
    Uint8List payload, {
    required int timestamp,
    bool marker = false,
  }) => _buildRtp(payload, marker: marker, timestamp: timestamp);

  List<Uint8List> _fragment(Uint8List data, H264NalUnit nal) {
    final packets = <Uint8List>[];

    final nalHeader = data[0];
    final fuIndicator = (nalHeader & 0xe0) | 28; // FU-A type = 28
    final nalType = nalHeader & 0x1f;

    var offset = 1; // Skip the NAL header byte; it is carried in the FU header.
    var first = true;

    while (offset < data.length) {
      final end = math.min(offset + maxPayload - 2, data.length);
      final isLast = end >= data.length;

      var fuHeader = nalType;
      if (first) fuHeader |= 0x80; // Start bit.
      if (isLast) fuHeader |= 0x40; // End bit.

      final payload = BytesBuilder()
        ..addByte(fuIndicator)
        ..addByte(fuHeader)
        ..add(data.sublist(offset, end));

      packets.add(
        _buildRtp(
          payload.toBytes(),
          marker: nal.lastOfFrame && isLast,
          timestamp: nal.timestamp,
        ),
      );

      offset = end;
      first = false;
    }

    return packets;
  }

  Uint8List _buildRtp(
    Uint8List payload, {
    required bool marker,
    required int timestamp,
  }) {
    final packet = BytesBuilder()
      ..addByte(0x80) // V=2, P=0, X=0, CC=0
      ..addByte((marker ? 0x80 : 0x00) | (payloadType & 0x7f))
      ..addByte((_sequence >> 8) & 0xff)
      ..addByte(_sequence & 0xff)
      ..addByte((timestamp >> 24) & 0xff)
      ..addByte((timestamp >> 16) & 0xff)
      ..addByte((timestamp >> 8) & 0xff)
      ..addByte(timestamp & 0xff)
      ..addByte((ssrc >> 24) & 0xff)
      ..addByte((ssrc >> 16) & 0xff)
      ..addByte((ssrc >> 8) & 0xff)
      ..addByte(ssrc & 0xff)
      ..add(payload);

    _sequence = (_sequence + 1) & 0xffff;

    return packet.toBytes();
  }
}
