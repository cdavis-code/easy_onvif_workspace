import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A browser-only live-video player that receives the server's WebRTC stream.
///
/// Connects to the server's `/onvif/webrtc` signaling WebSocket, negotiates a
/// receive-only peer connection, and renders the incoming track. Used on
/// Flutter web, where the RTSP stream cannot play; native platforms use
/// media_kit instead.
class WebrtcPlayer extends StatefulWidget {
  /// The server's `host:port` (e.g. `192.168.1.50:8080`).
  final String host;

  /// ONVIF credentials, sent as query parameters on the signaling WebSocket
  /// (the upgrade is rejected without them).
  final String username;
  final String password;

  const WebrtcPlayer({
    super.key,
    required this.host,
    required this.username,
    required this.password,
  });

  @override
  State<WebrtcPlayer> createState() => _WebrtcPlayerState();
}

class _WebrtcPlayerState extends State<WebrtcPlayer> {
  final _renderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  WebSocketChannel? _channel;
  MediaStream? _remoteStream;
  String? _error;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _renderer.initialize();

      final pc = await createPeerConnection({
        'iceServers': <Map<String, dynamic>>[],
      });
      _pc = pc;

      pc.onTrack = (event) {
        if (_disposed || event.streams.isEmpty) return;
        setState(() {
          _remoteStream = event.streams.first;
          _renderer.srcObject = _remoteStream;
        });
      };

      pc.onIceCandidate = (candidate) {
        _channel?.sink.add(
          jsonEncode({
            'type': 'candidate',
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }),
        );
      };

      // Receive-only transceivers: the server sends, the browser only receives.
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      final channel = WebSocketChannel.connect(_signalingUri());
      _channel = channel;

      channel.stream.listen(
        (data) async {
          if (_disposed) return;
          final message = jsonDecode(data as String) as Map<String, dynamic>;
          switch (message['type']) {
            case 'answer':
              await pc.setRemoteDescription(
                RTCSessionDescription(message['sdp'] as String?, 'answer'),
              );
            case 'candidate':
              await pc.addCandidate(
                RTCIceCandidate(
                  message['candidate'] as String?,
                  message['sdpMid'] as String?,
                  (message['sdpMLineIndex'] as num?)?.toInt(),
                ),
              );
            case 'error':
              if (!_disposed) {
                setState(() => _error ??= message['message'] as String?);
              }
          }
        },
        onDone: () {
          // The server closed the signaling socket (session replaced by a
          // newer viewer, or the server stopped).
          if (!_disposed) {
            setState(() => _error ??= 'Connection closed by the server');
          }
        },
        onError: (Object error) {
          if (!_disposed) setState(() => _error ??= '$error');
        },
      );

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      channel.sink.add(jsonEncode({'type': 'offer', 'sdp': offer.sdp}));
    } catch (error) {
      if (!_disposed) setState(() => _error ??= '$error');
      // Tear down anything created before the failure so the peer connection
      // and socket don't leak while the error is on screen.
      await _channel?.sink.close();
      _channel = null;
      await _pc?.close();
      _pc = null;
    }
  }

  /// Builds the authenticated signaling URL from [widget.host] (`host:port`).
  Uri _signalingUri() {
    final parts = widget.host.split(':');
    return Uri(
      scheme: 'ws',
      host: parts.first,
      port: parts.length > 1 ? int.tryParse(parts[1]) : null,
      path: '/onvif/webrtc',
      queryParameters: {
        'username': widget.username,
        'password': widget.password,
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    // Null the rendered stream before disposing so RTCVideoView never rebuilds
    // against a torn-down renderer.
    _renderer.srcObject = null;
    _remoteStream = null;
    _channel?.sink.close();
    _pc?.close();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Live video unavailable: $error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RTCVideoView(
      _renderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    );
  }
}
