/// Key material handling: parsing operator-supplied keys, generating new ones,
/// and deriving one from a passphrase (Argon2id).
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// AES-256 needs 32 bytes.
const int keyLength = 32;

/// Salt length for Argon2id. 16 bytes is the RFC 9106 minimum.
const int kdfSaltLength = 16;

final Random _random = Random.secure();

/// A fresh 32-byte key from the platform CSPRNG.
List<int> generateKey() =>
    List<int>.generate(keyLength, (_) => _random.nextInt(256));

/// Parses key material as either base64 or hex; anything that is not exactly
/// 32 bytes is rejected rather than silently truncated.
List<int> parseKeyMaterial(String text) {
  final trimmed = text.trim();
  final bytes = _looksHex(trimmed)
      ? _fromHex(trimmed)
      : base64.decode(trimmed.replaceAll(RegExp(r'\s'), ''));
  if (bytes.length != keyLength) {
    throw FormatException(
      'key material must be $keyLength bytes, got ${bytes.length}',
    );
  }
  return bytes;
}

/// The key id stored in an envelope: first 8 bytes of SHA-256, lowercase hex.
///
/// It identifies *which* key sealed a file without revealing the key, so a
/// mismatch can be reported as "encrypted with a1b2…, you supplied 9f8e…"
/// instead of an unexplained authentication failure.
String kidOf(List<int> key) =>
    crypto.sha256.convert(key).bytes.take(8).map(_hexByte).join();

/// Argon2id parameters, stored in the envelope so the file stays readable if
/// these defaults are ever raised.
final class KdfSpec {
  /// Memory cost in KiB. 19 MiB is the OWASP baseline and fits in wasm.
  final int memory;

  final int iterations;
  final int parallelism;
  final List<int> salt;

  const KdfSpec({
    required this.salt,
    this.memory = 19456,
    this.iterations = 2,
    this.parallelism = 1,
  });

  /// A spec with a fresh random salt.
  factory KdfSpec.random() => KdfSpec(
    salt: List<int>.generate(kdfSaltLength, (_) => _random.nextInt(256)),
  );

  /// Parses `argon2id:m=19456,t=2,p=1,salt=<base64>`.
  factory KdfSpec.parse(String text) {
    const prefix = 'argon2id:';
    if (!text.startsWith(prefix)) {
      throw const FormatException('unsupported kdf (expected argon2id)');
    }
    final params = <String, String>{};
    for (final part in text.substring(prefix.length).split(',')) {
      final eq = part.indexOf('=');
      if (eq <= 0) throw FormatException('malformed kdf parameter "$part"');
      params[part.substring(0, eq)] = part.substring(eq + 1);
    }
    final salt = params['salt'];
    if (salt == null) throw const FormatException('kdf is missing a salt');
    return KdfSpec(
      salt: base64.decode(salt),
      memory: int.parse(params['m'] ?? '19456'),
      iterations: int.parse(params['t'] ?? '2'),
      parallelism: int.parse(params['p'] ?? '1'),
    );
  }

  String format() =>
      'argon2id:m=$memory,t=$iterations,p=$parallelism,'
      'salt=${base64.encode(salt)}';

  /// Derives the 32-byte key. This is deliberately slow; it runs once per start.
  Future<List<int>> derive(String passphrase) async {
    final kdf = Argon2id(
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: keyLength,
    );
    final secret = await kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    return secret.extractBytes();
  }
}

bool _looksHex(String text) =>
    text.length == keyLength * 2 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(text);

List<int> _fromHex(String text) => [
  for (var i = 0; i < text.length; i += 2)
    int.parse(text.substring(i, i + 2), radix: 16),
];

String _hexByte(int byte) => byte.toRadixString(16).padLeft(2, '0');
