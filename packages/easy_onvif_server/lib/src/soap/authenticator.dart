import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'request_context.dart';

/// Validates WS-Security `UsernameToken` credentials using the ONVIF password
/// digest scheme, with replay protection.
///
/// The digest is defined (see `Authorization.digest` in the `easy_onvif`
/// client) as:
///
/// ```
/// PasswordDigest = Base64( SHA1( nonceBytes + Created + Password ) )
/// ```
///
/// where `nonceBytes` is the Base64-decoded `Nonce`, and `Created` and
/// `Password` are UTF-8 encoded. The server recomputes the digest with the
/// stored password and compares it to the value supplied by the client.
///
/// Beyond the digest, the validator rejects requests whose `Created` timestamp
/// falls outside [timestampWindow] (stale/clock-skew protection) and requests
/// that reuse a recently seen `Nonce` (replay protection).
class Authenticator {
  final String expectedUsername;
  final String expectedPassword;

  /// Maximum allowed age — and future skew — of a request's `Created`
  /// timestamp before it is rejected as stale.
  final Duration timestampWindow;

  final int _nonceCapacity;

  /// Recently accepted nonces (newest last), for replay detection.
  final Set<String> _seenNonces = <String>{};
  final Queue<String> _nonceOrder = Queue<String>();

  Authenticator({
    required this.expectedUsername,
    required this.expectedPassword,
    this.timestampWindow = const Duration(minutes: 5),
    int nonceCapacity = 1024,
  }) : _nonceCapacity = nonceCapacity;

  /// Returns `true` if [credentials] are valid for the configured user.
  bool verify(UsernameTokenCredentials? credentials) {
    if (credentials == null) return false;

    if (credentials.username != expectedUsername) return false;

    // Reject timestamps outside the freshness window (replay/stale requests).
    final created = DateTime.tryParse(credentials.created);
    if (created == null) return false;

    final skew = DateTime.now().toUtc().difference(created.toUtc()).abs();
    if (skew > timestampWindow) return false;

    final expectedDigest = _digest(
      nonceBase64: credentials.nonce,
      created: credentials.created,
      password: expectedPassword,
    );

    if (!_constantTimeEquals(expectedDigest, credentials.passwordDigest)) {
      return false;
    }

    // Reject a nonce we have already accepted (a replayed request).
    return _acceptNonce(credentials.nonce);
  }

  /// Records [nonce] as seen, returning `false` if it was already used. The
  /// cache is bounded to the configured capacity (oldest evicted first) so it
  /// cannot grow without limit.
  bool _acceptNonce(String nonce) {
    if (_seenNonces.contains(nonce)) return false;

    _seenNonces.add(nonce);
    _nonceOrder.addLast(nonce);

    while (_nonceOrder.length > _nonceCapacity) {
      _seenNonces.remove(_nonceOrder.removeFirst());
    }

    return true;
  }

  /// Compares two digest strings without an early exit, so the comparison time
  /// does not leak how many leading characters matched (timing side-channel).
  static bool _constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);

    if (aBytes.length != bBytes.length) return false;

    var result = 0;
    for (var i = 0; i < aBytes.length; i++) {
      result |= aBytes[i] ^ bBytes[i];
    }

    return result == 0;
  }

  static String _digest({
    required String nonceBase64,
    required String created,
    required String password,
  }) {
    final nonceBytes = base64.decode(nonceBase64);

    return base64.encode(
      sha1
          .convert(nonceBytes + utf8.encode(created) + utf8.encode(password))
          .bytes,
    );
  }
}
