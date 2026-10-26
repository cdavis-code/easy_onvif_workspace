/// The sealed credential file: a versioned JSON envelope around an
/// AES-256-GCM ciphertext.
///
/// The header (`v`, `alg`, `kid`, `kdf`) is authenticated as additional data,
/// so tampering with it invalidates the tag instead of silently downgrading the
/// algorithm. Pure Dart: this file compiles unchanged to the VM, to dart2js
/// (the npm Node bundle) and to dartwasm (the browser build).
library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'bundle.dart';
import 'keys.dart';

/// Bumped only when the envelope layout changes incompatibly.
const int envelopeVersion = 1;

const String envelopeAlg = 'A256GCM';

/// `kdf` value for a directly supplied key (env, key file, keychain, host).
const String kdfNone = 'none';

const int _macLength = 16;

/// Whether a parsed JSON object is a sealed envelope rather than a legacy
/// plaintext credentials map.
bool looksEncrypted(Map<String, dynamic> json) =>
    json['ct'] is String && json['v'] is int;

/// Seals [bundle] with [key], or with a passphrase-derived key when
/// [passphrase] is given (a fresh salt is generated unless [kdf] supplies one).
Future<Map<String, dynamic>> sealBundle(
  DeviceBundle bundle, {
  List<int>? key,
  String? passphrase,
  KdfSpec? kdf,
}) => sealBytes(
  utf8.encode(jsonEncode(bundle.toJson())),
  key: key,
  passphrase: passphrase,
  kdf: kdf,
);

/// Seals raw bytes and returns the envelope object.
Future<Map<String, dynamic>> sealBytes(
  List<int> plain, {
  List<int>? key,
  String? passphrase,
  KdfSpec? kdf,
}) async {
  final spec = passphrase == null ? null : (kdf ?? KdfSpec.random());
  final secret = passphrase == null ? key : await spec!.derive(passphrase);
  if (secret == null) {
    throw ArgumentError('sealBytes needs either a key or a passphrase');
  }

  final kid = kidOf(secret);
  final kdfText = spec?.format() ?? kdfNone;
  final box = await AesGcm.with256bits().encrypt(
    plain,
    secretKey: SecretKey(secret),
    aad: _aad(kid, kdfText),
  );

  return {
    'v': envelopeVersion,
    'alg': envelopeAlg,
    'kid': kid,
    'kdf': kdfText,
    'nonce': base64.encode(box.nonce),
    'ct': base64.encode([...box.cipherText, ...box.mac.bytes]),
  };
}

/// Opens an envelope back to raw bytes.
///
/// The header is validated before any decryption so a future format or a
/// corrupted `kid` produces a precise error rather than a bare MAC failure.
Future<List<int>> openBytes(
  Map<String, dynamic> envelope, {
  List<int>? key,
  String? passphrase,
}) async {
  final version = envelope['v'];
  if (version != envelopeVersion) {
    throw CredentialsFormatException(
      'unsupported credential file version "$version" (this build reads '
      '$envelopeVersion)',
    );
  }
  final alg = envelope['alg'];
  if (alg != envelopeAlg) {
    throw CredentialsFormatException('unsupported cipher "$alg"');
  }
  final kid = envelope['kid'];
  final kdfText = envelope['kdf'];
  final nonce = envelope['nonce'];
  final cipherText = envelope['ct'];
  if (kid is! String ||
      kdfText is! String ||
      nonce is! String ||
      cipherText is! String) {
    throw const CredentialsFormatException('credential file is malformed');
  }

  final KdfSpec? spec;
  try {
    spec = kdfText == kdfNone ? null : KdfSpec.parse(kdfText);
  } on FormatException catch (error) {
    throw CredentialsFormatException(
      'credential file is malformed (${error.message})',
    );
  }
  final List<int> secret;
  if (spec == null) {
    if (key == null) {
      throw const CredentialsFormatException(
        'this credential file needs a key (kdf: none)',
      );
    }
    secret = key;
  } else {
    if (passphrase == null) {
      throw const CredentialsFormatException(
        'this credential file needs a passphrase (kdf: argon2id)',
      );
    }
    secret = await spec.derive(passphrase);
  }

  // Compare key ids before spending effort on decryption, so the operator is
  // told which key the file wants instead of seeing "authentication failed".
  final suppliedKid = kidOf(secret);
  if (suppliedKid != kid) {
    throw CredentialsFormatException(
      'credential file was encrypted with key $kid, but the supplied key is '
      '$suppliedKid',
    );
  }

  final List<int> raw;
  final List<int> nonceBytes;
  try {
    raw = base64.decode(cipherText);
    nonceBytes = base64.decode(nonce);
  } on FormatException {
    throw const CredentialsFormatException('credential file is malformed');
  }
  if (raw.length <= _macLength) {
    throw const CredentialsFormatException('credential file is truncated');
  }
  final box = SecretBox(
    raw.sublist(0, raw.length - _macLength),
    nonce: nonceBytes,
    mac: Mac(raw.sublist(raw.length - _macLength)),
  );

  try {
    return await AesGcm.with256bits().decrypt(
      box,
      secretKey: SecretKey(secret),
      aad: _aad(kid, kdfText),
    );
  } on SecretBoxAuthenticationError {
    throw const CredentialsFormatException(
      'credential file failed authentication (corrupted or tampered with)',
    );
  }
}

/// Opens an envelope back to a [DeviceBundle].
Future<DeviceBundle> openBundle(
  Map<String, dynamic> envelope, {
  List<int>? key,
  String? passphrase,
}) async {
  final plain = await openBytes(envelope, key: key, passphrase: passphrase);
  final decoded = jsonDecode(utf8.decode(plain));
  if (decoded is! Map<String, dynamic>) {
    throw const CredentialsFormatException(
      'decrypted payload is not an object',
    );
  }
  return DeviceBundle.fromJson(decoded);
}

/// The header fields bound into the AEAD tag.
List<int> _aad(String kid, String kdfText) =>
    utf8.encode('$envelopeVersion|$envelopeAlg|$kid|$kdfText');
