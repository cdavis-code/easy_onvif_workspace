import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:loggy/loggy.dart';

import '../settings.dart';
import 'webrtc_session.dart';

/// A [WebrtcSession] backed by `flutter_webrtc`: captures the configured media
/// source (camera or display, plus microphone) and streams it to the browser
/// over an [RTCPeerConnection]. libwebrtc encodes the tracks (H.264/Opus).
class NativeWebrtcSession with UiLoggy implements WebrtcSession {
  NativeWebrtcSession({required this.media, required this.send});

  final MediaSettings media;

  /// Reports outgoing signaling messages (ICE candidates) to the browser.
  final void Function(Map<String, dynamic> message) send;

  RTCPeerConnection? _pc;
  final List<MediaStream> _streams = [];

  @override
  Future<void> start() async {
    final pc = await createPeerConnection({
      'iceServers': <Map<String, dynamic>>[],
    });

    pc.onIceCandidate = (candidate) {
      send({
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _pc = pc;

    await _capture(pc);
  }

  Future<void> _capture(RTCPeerConnection pc) async {
    switch (media.videoSource) {
      case VideoSourceKind.display:
        // Screen video + (optionally) microphone audio, from two captures.
        final display = await navigator.mediaDevices.getDisplayMedia({
          'video': true,
        });
        _streams.add(display);
        for (final track in display.getVideoTracks()) {
          await pc.addTrack(track, display);
        }

        if (media.audioEnabled) {
          final mic = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
          _streams.add(mic);
          for (final track in mic.getAudioTracks()) {
            await pc.addTrack(track, mic);
          }
        }

      case VideoSourceKind.camera:
      case VideoSourceKind.test:
        // flutter_webrtc cannot synthesize a test pattern; `test` falls back
        // to the default camera.
        final camera = await navigator.mediaDevices.getUserMedia({
          'video': true,
          'audio': media.audioEnabled,
        });
        _streams.add(camera);
        for (final track in camera.getTracks()) {
          await pc.addTrack(track, camera);
        }
    }
  }

  @override
  Future<void> handleOffer(String sdp) async {
    final pc = _pc;
    if (pc == null) throw StateError('Session not started');

    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    send({'type': 'answer', 'sdp': answer.sdp});
  }

  @override
  Future<void> addRemoteCandidate(
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    await _pc?.addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
  }

  @override
  Future<void> dispose() async {
    for (final stream in _streams) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }
    _streams.clear();

    await _pc?.close();
    _pc = null;
  }
}
