import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/soap/authenticator.dart';
import 'package:easy_onvif_server/src/soap/request_context.dart';

/// Builds WS-Security credentials the same way the `easy_onvif` client does:
/// `PasswordDigest = Base64( SHA1( nonceBytes + Created + Password ) )`.
UsernameTokenCredentials _credentials({
  String username = 'admin',
  String password = 'secret',
  String? nonceBase64,
  String? created,
}) {
  final nonce = nonceBase64 ?? base64.encode(List.generate(16, (i) => i + 1));
  final createdTimestamp = created ?? DateTime.now().toUtc().toIso8601String();
  final digest = base64.encode(
    sha1
        .convert(
          base64.decode(nonce) +
              utf8.encode(createdTimestamp) +
              utf8.encode(password),
        )
        .bytes,
  );

  return UsernameTokenCredentials(
    username: username,
    passwordDigest: digest,
    nonce: nonce,
    created: createdTimestamp,
  );
}

void main() {
  test('accepts valid credentials', () {
    final authenticator = Authenticator(
      expectedUsername: 'admin',
      expectedPassword: 'secret',
    );

    expect(authenticator.verify(_credentials()), isTrue);
  });

  test('rejects a wrong password', () {
    final authenticator = Authenticator(
      expectedUsername: 'admin',
      expectedPassword: 'secret',
    );

    expect(authenticator.verify(_credentials(password: 'wrong')), isFalse);
  });

  test('rejects a wrong username', () {
    final authenticator = Authenticator(
      expectedUsername: 'admin',
      expectedPassword: 'secret',
    );

    expect(authenticator.verify(_credentials(username: 'eve')), isFalse);
  });

  test('rejects a replayed nonce', () {
    final authenticator = Authenticator(
      expectedUsername: 'admin',
      expectedPassword: 'secret',
    );

    final nonce = base64.encode(List.generate(16, (i) => i + 100));

    // First use is accepted; the same nonce again is a replay.
    expect(authenticator.verify(_credentials(nonceBase64: nonce)), isTrue);
    expect(authenticator.verify(_credentials(nonceBase64: nonce)), isFalse);
  });

  test('rejects a stale Created timestamp', () {
    final authenticator = Authenticator(
      expectedUsername: 'admin',
      expectedPassword: 'secret',
    );

    final stale = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 10))
        .toIso8601String();

    expect(authenticator.verify(_credentials(created: stale)), isFalse);
  });

  test('rejects an unparseable Created timestamp', () {
    final authenticator = Authenticator(
      expectedUsername: 'admin',
      expectedPassword: 'secret',
    );

    expect(
      authenticator.verify(_credentials(created: 'not-a-timestamp')),
      isFalse,
    );
  });
}
