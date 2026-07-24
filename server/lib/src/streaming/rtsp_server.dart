import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:loggy/loggy.dart';

import 'h264_source.dart';
import 'rtp_packetizer.dart';

/// A minimal RTSP server that serves a single H.264 stream (from a
/// [NalStreamSource]) over RTP/AVP/TCP (RTP interleaved on the RTSP TCP
/// connection).
///
/// Supports the OPTIONS / DESCRIBE / SETUP / PLAY / TEARDOWN methods, which is
/// sufficient for clients such as VLC and ffprobe to play the stream.
class RtspServer with UiLoggy {
  final NalStreamSource source;
  final int port;

  ServerSocket? _serverSocket;
  final Set<_RtspConnection> _connections = {};

  RtspServer({required this.source, required this.port});

  bool get isRunning => _serverSocket != null;

  Future<void> start() async {
    if (_serverSocket != null) return;

    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);

    loggy.info('RTSP server listening on port $port');

    // Run the accept loop and every connection inside a guarded zone so that
    // asynchronous socket errors (connection resets, broken pipes) tear down
    // the affected session instead of propagating uncaught to the caller.
    runZonedGuarded(
      () {
        _serverSocket!.listen((socket) {
          final connection = _RtspConnection(this, socket);
          _connections.add(connection);
          connection.run();
        }, onError: (Object error) => loggy.debug('RTSP accept error: $error'));
      },
      (error, stackTrace) {
        loggy.debug('RTSP server zone error: $error');
      },
    );
  }

  Future<void> stop() async {
    for (final connection in _connections.toList()) {
      await connection.close();
    }
    _connections.clear();

    await _serverSocket?.close();
    _serverSocket = null;
  }

  void _remove(_RtspConnection connection) => _connections.remove(connection);

  String _buildSdp(String baseUrl) {
    final sps = source.sps;
    final pps = source.pps;

    final profileLevelId = (sps != null && sps.length >= 4)
        ? [
            sps[1],
            sps[2],
            sps[3],
          ].map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join()
        : '42C01E';

    final sprop = [
      if (sps != null) base64.encode(sps),
      if (pps != null) base64.encode(pps),
    ].join(',');

    return [
      'v=0',
      'o=- ${DateTime.now().millisecondsSinceEpoch} 1 IN IP4 0.0.0.0',
      's=ONVIF Stream',
      'c=IN IP4 0.0.0.0',
      't=0 0',
      'm=video 0 RTP/AVP 96',
      'a=rtpmap:96 H264/90000',
      'a=fmtp:96 packetization-mode=1;profile-level-id=$profileLevelId;'
          'sprop-parameter-sets=$sprop',
      'a=control:trackID=0',
      '',
    ].join('\r\n');
  }
}

class _RtspConnection {
  final RtspServer server;
  final Socket socket;

  final List<int> _buffer = [];

  final String _sessionId = DateTime.now().microsecondsSinceEpoch.toRadixString(
    16,
  );

  int _rtpChannel = 0;

  bool _playing = false;

  bool _closed = false;

  StreamSubscription<H264NalUnit>? _nalSubscription;

  late final RtpPacketizer _packetizer = RtpPacketizer();

  _RtspConnection(this.server, this.socket);

  void run() {
    socket.listen(
      _onData,
      onDone: close,
      onError: (_) => close(),
      cancelOnError: true,
    );

    // Ensure resources are released if the peer resets the connection.
    socket.done.then((_) => close(), onError: (_) => close());
  }

  void _onData(List<int> data) {
    _buffer.addAll(data);

    _processBuffer();
  }

  void _processBuffer() {
    while (_buffer.isNotEmpty) {
      if (_buffer.first == 0x24) {
        // Interleaved binary frame from the client (e.g. RTCP RR): skip it.
        if (_buffer.length < 4) return;

        final length = (_buffer[2] << 8) | _buffer[3];

        if (_buffer.length < 4 + length) return;

        _buffer.removeRange(0, 4 + length);

        continue;
      }

      final headerEnd = _indexOfHeaderEnd();

      if (headerEnd < 0) return; // Wait for the rest of the request.

      final raw = utf8.decode(
        _buffer.sublist(0, headerEnd),
        allowMalformed: true,
      );

      _buffer.removeRange(0, headerEnd + 4);

      _handleRequest(raw);
    }
  }

  int _indexOfHeaderEnd() {
    for (var i = 0; i + 3 < _buffer.length; i++) {
      if (_buffer[i] == 0x0d &&
          _buffer[i + 1] == 0x0a &&
          _buffer[i + 2] == 0x0d &&
          _buffer[i + 3] == 0x0a) {
        return i;
      }
    }

    return -1;
  }

  void _handleRequest(String raw) {
    final lines = raw.split('\r\n');

    if (lines.isEmpty) return;

    final requestLine = lines.first.split(' ');

    if (requestLine.length < 2) return;

    final method = requestLine[0].toUpperCase();
    final url = requestLine[1];

    final headers = <String, String>{};

    for (final line in lines.skip(1)) {
      final index = line.indexOf(':');

      if (index > 0) {
        headers[line.substring(0, index).trim().toLowerCase()] = line
            .substring(index + 1)
            .trim();
      }
    }

    final cseq = int.tryParse(headers['cseq'] ?? '') ?? 0;

    server.loggy.debug('RTSP $method $url');

    switch (method) {
      case 'OPTIONS':
        _respond(
          cseq,
          headers: {'Public': 'OPTIONS, DESCRIBE, SETUP, PLAY, TEARDOWN'},
        );

      case 'DESCRIBE':
        _handleDescribe(cseq, url);

      case 'SETUP':
        _handleSetup(cseq, headers);

      case 'PLAY':
        _handlePlay(cseq, url);

      case 'TEARDOWN':
        _respond(cseq, headers: {'Session': _sessionId});
        _stopStreaming();

      default:
        _respond(cseq, status: 405, reason: 'Method Not Allowed');
    }
  }

  Future<void> _handleDescribe(int cseq, String url) async {
    // Ensure SPS/PPS are available so the SDP is valid.
    await server.source.parametersReady.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );

    final base = url.endsWith('/') ? url : '$url/';
    final sdp = server._buildSdp(base);

    _respond(
      cseq,
      headers: {'Content-Type': 'application/sdp', 'Content-Base': base},
      body: sdp,
    );
  }

  void _handleSetup(int cseq, Map<String, String> headers) {
    final transport = headers['transport'] ?? '';

    final interleaved = RegExp(
      r'interleaved=(\d+)-(\d+)',
    ).firstMatch(transport);

    if (interleaved != null) {
      _rtpChannel = int.parse(interleaved.group(1)!);
    }

    _respond(
      cseq,
      headers: {
        'Transport':
            'RTP/AVP/TCP;unicast;interleaved=$_rtpChannel-${_rtpChannel + 1}',
        'Session': _sessionId,
      },
    );
  }

  void _handlePlay(int cseq, String url) {
    _respond(
      cseq,
      headers: {
        'Session': _sessionId,
        'Range': 'npt=0.000-',
        'RTP-Info': 'url=$url/trackID=0;seq=0;rtptime=0',
      },
    );

    _startStreaming();
  }

  void _startStreaming() {
    if (_playing) return;

    _playing = true;

    _nalSubscription = server.source.nals.listen((nal) {
      if (!_playing) return;

      try {
        for (final packet in _packetizer.packetize(nal)) {
          _sendInterleaved(packet);
        }
      } catch (_) {
        // A write failure means the client went away; close the session.
        close();
      }
    });
  }

  void _stopStreaming() {
    _playing = false;

    _nalSubscription?.cancel();
    _nalSubscription = null;
  }

  void _sendInterleaved(Uint8List rtpPacket) {
    final frame = BytesBuilder()
      ..addByte(0x24)
      ..addByte(_rtpChannel)
      ..addByte((rtpPacket.length >> 8) & 0xff)
      ..addByte(rtpPacket.length & 0xff)
      ..add(rtpPacket);

    _safeAdd(frame.toBytes());
  }

  void _respond(
    int cseq, {
    Map<String, String> headers = const {},
    String body = '',
    int status = 200,
    String reason = 'OK',
  }) {
    final buffer = StringBuffer()..write('RTSP/1.0 $status $reason\r\n');

    buffer.write('CSeq: $cseq\r\n');

    headers.forEach((key, value) => buffer.write('$key: $value\r\n'));

    final bodyBytes = utf8.encode(body);

    if (bodyBytes.isNotEmpty) {
      buffer.write('Content-Length: ${bodyBytes.length}\r\n');
    }

    buffer.write('\r\n');

    _safeAdd(utf8.encode(buffer.toString()));

    if (bodyBytes.isNotEmpty) _safeAdd(bodyBytes);
  }

  /// Writes [data] to the socket, swallowing write errors (e.g. a broken pipe
  /// when the peer has disconnected) and tearing down the session instead of
  /// letting the error propagate.
  void _safeAdd(List<int> data) {
    if (_closed) return;

    try {
      socket.add(data);
    } catch (_) {
      // The peer disconnected mid-write; tear down the session quietly.
      close();
    }
  }

  Future<void> close() async {
    if (_closed) return;

    _closed = true;

    _stopStreaming();

    server._remove(this);

    try {
      // destroy() closes immediately without flushing pending writes, so it does not
      // throw for an already-broken socket the way close() can.
      socket.destroy();
    } catch (_) {
      // Ignore errors tearing down a broken socket.
    }
  }
}
