import 'dart:async';
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
/// is active at a time. A new connection preempts the previous one: its session
/// is disposed and its socket closed (with an error) so the evicted client does
/// not hang. Session creation is serialized behind a lock so two near-
/// simultaneous connections cannot both capture the device.
class WebrtcService with UiLoggy {
  WebrtcService({
    required this.media,
    required WebrtcSessionFactory sessionFactory,
  }) : _sessionFactory = sessionFactory;

  /// The configured media source (video kind/device, audio enabled/device).
  final MediaSettings media;

  final WebrtcSessionFactory _sessionFactory;

  /// The current session and its socket. [_active] is assigned as soon as the
  /// session is created (before `start()` completes) so [dispose] can release
  /// an in-flight capture too.
  WebrtcSession? _active;
  WebSocket? _activeSocket;

  /// Serializes session creation (single-consumer capture).
  Future<void> _creationLock = Future.value();

  /// Handles one upgraded WebSocket signaling connection. Never throws:
  /// failures are logged and reported to the client over the socket.
  Future<void> handleConnection(WebSocket socket) {
    final result = _creationLock.then((_) => _handleConnectionLocked(socket));

    // Keep the chain alive regardless of outcome, and don't surface errors to
    // the fire-and-forget caller (they are logged/reported internally).
    _creationLock = result.then((_) {}, onError: (Object _) {});

    return result.then((_) {}, onError: (Object _) {});
  }

  Future<void> _handleConnectionLocked(WebSocket socket) async {
    // Single-consumer capture: preempt the previous session and close its
    // socket so the evicted client gets an error instead of hanging.
    final previous = _active;
    final previousSocket = _activeSocket;
    _active = null;
    _activeSocket = null;
    await _safeDispose(previous);
    if (previousSocket != null) {
      try {
        previousSocket.add(jsonEncode({
          'type': 'error',
          'message': 'Session replaced by a newer connection',
        }));
        await previousSocket.close();
      } catch (_) {
        // The previous client already left; nothing to notify.
      }
    }

    void send(Map<String, dynamic> message) {
      try {
        socket.add(jsonEncode(message));
      } catch (_) {
        // The peer disconnected mid-write; teardown follows via onDone.
      }
    }

    final session = _sessionFactory(send);

    // Track the session before starting it so dispose() can release the
    // capture device even if start() is still in flight.
    _active = session;
    _activeSocket = socket;

    try {
      await session.start();
    } catch (error) {
      loggy.warning('WebRTC capture failed: $error');
      send({'type': 'error', 'message': '$error'});
      await _safeDispose(session);
      if (_active == session) {
        _active = null;
        _activeSocket = null;
      }
      try {
        await socket.close();
      } catch (_) {}
      return;
    }

    // Serialize signaling messages so a trickle candidate is never applied
    // before the offer's remote description is set.
    var messageQueue = Future<void>.value();
    void enqueue(Future<void> Function() action) {
      messageQueue = messageQueue.then((_) => action()).then((_) {},
          onError: (Object error) {
        loggy.warning('WebRTC signaling error: $error');
      });
    }

    // Idempotent teardown: both onDone and onError may fire.
    var tornDown = false;
    Future<void> teardown() async {
      if (tornDown) return;
      tornDown = true;
      await _safeDispose(session);
      if (_active == session) {
        _active = null;
        _activeSocket = null;
      }
    }

    socket.listen(
      (data) {
        enqueue(() async {
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
        });
      },
      onDone: teardown,
      onError: (Object error) {
        loggy.debug('WebRTC socket error: $error');
        teardown();
      },
    );
  }

  Future<void> _safeDispose(WebrtcSession? session) async {
    if (session == null) return;
    try {
      await session.dispose();
    } catch (error) {
      loggy.warning('Error disposing WebRTC session: $error');
    }
  }

  /// Disposes the active (or still-starting) session and closes its socket.
  /// Called on server shutdown.
  Future<void> dispose() async {
    final active = _active;
    final socket = _activeSocket;
    _active = null;
    _activeSocket = null;
    await _safeDispose(active);
    try {
      await socket?.close();
    } catch (_) {}
  }
}
