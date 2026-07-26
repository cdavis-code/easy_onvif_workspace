import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

import '../settings.dart';
import 'webrtc_session.dart';

/// Builds a [WebrtcSession] that reports outgoing signaling messages through
/// [send]. Injected so tests can substitute a fake session.
typedef WebrtcSessionFactory =
    WebrtcSession Function(void Function(Map<String, dynamic> message) send);

/// Manages browser WebRTC sessions for the `/onvif/webrtc` signaling endpoint.
///
/// Capture is single-consumer (one camera/screen owner), so at most one session
/// is active at a time: a new connection disposes the previous session before
/// starting its own capture.
class WebrtcService with UiLoggy {
  WebrtcService({
    required this.media,
    required WebrtcSessionFactory sessionFactory,
  }) : _sessionFactory = sessionFactory;

  /// The configured media source (video kind/device, audio enabled/device).
  final MediaSettings media;

  final WebrtcSessionFactory _sessionFactory;

  WebrtcSession? _active;

  /// Handles one upgraded WebSocket signaling connection.
  Future<void> handleConnection(WebSocket socket) async {
    // Single-consumer capture: tear down any in-progress session first.
    final previous = _active;
    _active = null;
    await previous?.dispose();

    void send(Map<String, dynamic> message) {
      try {
        socket.add(jsonEncode(message));
      } catch (_) {
        // The peer disconnected mid-write; teardown follows via onDone.
      }
    }

    final session = _sessionFactory(send);

    try {
      await session.start();
    } catch (error) {
      loggy.warning('WebRTC capture failed: $error');
      send({'type': 'error', 'message': '$error'});
      await session.dispose();
      await socket.close();
      return;
    }

    _active = session;

    Future<void> teardown() async {
      await session.dispose();
      if (_active == session) _active = null;
    }

    socket.listen(
      (data) async {
        try {
          final message = jsonDecode(data as String) as Map<String, dynamic>;
          switch (message['type']) {
            case 'offer':
              await session.handleOffer(message['sdp'] as String);
            case 'candidate':
              await session.addRemoteCandidate(
                message['candidate'] as String?,
                message['sdpMid'] as String?,
                (message['sdpMLineIndex'] as num?)?.toInt(),
              );
          }
        } catch (error) {
          loggy.warning('WebRTC signaling error: $error');
        }
      },
      onDone: teardown,
      onError: (_) => teardown(),
    );
  }

  /// Disposes the active session (called on server shutdown).
  Future<void> dispose() async {
    final active = _active;
    _active = null;
    await active?.dispose();
  }
}
