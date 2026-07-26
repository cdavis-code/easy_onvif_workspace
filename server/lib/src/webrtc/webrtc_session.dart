/// One browser WebRTC session: captures the configured media source and
/// streams it to a remote peer over a peer connection.
///
/// Transport-agnostic: outgoing signaling messages (ICE candidates) are
/// reported through the `send` callback supplied at construction; incoming
/// messages arrive via [handleOffer] and [addRemoteCandidate]. The WebSocket
/// plumbing lives in `WebrtcService`.
abstract interface class WebrtcSession {
  /// Captures the media source and prepares the peer connection. Must be
  /// called before [handleOffer]. Throws if capture fails (no device, denied
  /// permission, unsupported source).
  Future<void> start();

  /// Applies the browser's SDP offer and produces the answer, reported via the
  /// `send` callback as `{"type":"answer","sdp":...}`.
  Future<void> handleOffer(String sdp);

  /// Adds a trickle ICE candidate received from the browser.
  Future<void> addRemoteCandidate(
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  );

  /// Stops all captured tracks and closes the peer connection.
  Future<void> dispose();
}
