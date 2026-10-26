/// Browser build of the credential store.
///
/// A page has no filesystem, no environment and no keychain, so there is
/// nothing to *store*: the host passes the envelope and the key in memory (see
/// `loadCredentials` on the JS API) and [store.dart] resolves to this stub so
/// the rest of the package still compiles for the web.
library;

import 'bundle.dart';

/// Thrown when a storage operation is attempted where storage cannot exist.
final class CredentialsUnsupportedException implements Exception {
  final String message;

  const CredentialsUnsupportedException(this.message);

  @override
  String toString() => 'CredentialsUnsupportedException: $message';
}

/// No key could be found from any provider.
final class KeyUnavailableException implements Exception {
  final String message;

  const KeyUnavailableException(this.message);

  @override
  String toString() => 'KeyUnavailableException: $message';
}

/// Stand-in with the same surface as the IO implementation.
final class CredentialStore {
  const CredentialStore._();

  static Never _unsupported() => throw const CredentialsUnsupportedException(
    'credential files are not available in a browser; pass the envelope and '
    'key to loadCredentials() instead',
  );

  static Future<DeviceEntry> resolveDevice(
    String path, {
    String? deviceId,
    String? keyFile,
    bool allowPrompt = true,
    Map<String, String>? environment,
  }) async => _unsupported();

  static Future<BundleFile> readBundle(
    String path, {
    String? keyFile,
    bool allowPrompt = true,
    Map<String, String>? environment,
  }) async => _unsupported();

  static Future<String> writeBundle(
    String path,
    DeviceBundle bundle, {
    String? keyFile,
    bool usePassphrase = false,
    String? passphrase,
    Map<String, String>? environment,
  }) async => _unsupported();

  static Future<String> ensureKey({
    String? keyFile,
    Map<String, String>? environment,
  }) async => _unsupported();

  static Future<String> initKey({
    String? keyFile,
    Map<String, String>? environment,
  }) async => _unsupported();

  static Future<String> rotateKey({String? keyFile}) async => _unsupported();

  static Future<String> promptSecret(String label) async => _unsupported();
}
