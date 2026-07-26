import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'request_context.dart';

/// Validates WS-Security `UsernameToken` credentials using the ONVIF password
/// digest scheme.
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
class Authenticator {
  final String expectedUsername;
  final String expectedPassword;

  const Authenticator({
    required this.expectedUsername,
    required this.expectedPassword,
  });

  /// Returns `true` if [credentials] are valid for the configured user.
  bool verify(UsernameTokenCredentials? credentials) {
    if (credentials == null) return false;

    if (credentials.username != expectedUsername) return false;

    final expectedDigest = _digest(
      nonceBase64: credentials.nonce,
      created: credentials.created,
      password: expectedPassword,
    );

    return _constantTimeEquals(expectedDigest, credentials.passwordDigest);
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
