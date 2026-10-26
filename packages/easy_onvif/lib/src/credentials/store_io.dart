/// Credential store for the Dart VM: file IO, the key-provider chain and
/// OS keychain integration.
///
/// Everything the browser cannot do lives here; `store_stub.dart` is its
/// compile-time stand-in for the web build.
library;

import 'dart:convert';
import 'dart:io';

import 'bundle.dart';
import 'envelope.dart';
import 'keys.dart';

const String keyEnv = 'ONVIF_KEY';
const String keyFileEnv = 'ONVIF_KEY_FILE';
const String bundleEnv = 'ONVIF_BUNDLE';
const String deviceEnv = 'ONVIF_DEVICE';

const String _hostEnv = 'ONVIF_HOST';
const String _userEnv = 'ONVIF_USERNAME';
const String _passwordEnv = 'ONVIF_PASSWORD';

const String _keychainService = 'easy_onvif';
const String _keychainAccount = 'easy_onvif';

/// No key could be found from any provider.
final class KeyUnavailableException implements Exception {
  final String message;

  const KeyUnavailableException(this.message);

  @override
  String toString() => 'KeyUnavailableException: $message';
}

/// File-backed credential bundle with the provider chain of the design spec.
final class CredentialStore {
  const CredentialStore._();

  /// Reads [path] (encrypted envelope or legacy plaintext) and resolves the
  /// device: `ONVIF_HOST/USERNAME/PASSWORD` first, then [deviceId], then
  /// `ONVIF_DEVICE`, then the bundle's `default`.
  static Future<DeviceEntry> resolveDevice(
    String path, {
    String? deviceId,
    String? keyFile,
    bool allowPrompt = true,
    Map<String, String>? environment,
  }) async {
    final env = environment ?? Platform.environment;
    final override = _environmentDevice(env);
    if (override != null) return override;

    final file = await readBundle(
      path,
      keyFile: keyFile,
      allowPrompt: allowPrompt,
      environment: env,
    );
    return file.bundle.resolve(deviceId ?? env[deviceEnv]);
  }

  /// Reads [path]. A file without `ct` is treated as the pre-encryption shape.
  static Future<BundleFile> readBundle(
    String path, {
    String? keyFile,
    bool allowPrompt = true,
    Map<String, String>? environment,
  }) async {
    final env = environment ?? Platform.environment;
    final file = File(path);
    if (!file.existsSync()) {
      throw CredentialsFormatException('credential file not found: $path');
    }

    final decoded = _decodeObject(await file.readAsString());
    if (!looksEncrypted(decoded)) {
      return BundleFile(DeviceBundle.legacy(decoded), encrypted: false);
    }

    if (decoded['kdf'] == kdfNone) {
      final key = await _keyFromProviders(keyFile: keyFile, env: env);
      if (key == null) throw _missingKey();
      return BundleFile(await openBundle(decoded, key: key), encrypted: true);
    }

    if (!allowPrompt || !stdin.hasTerminal) {
      throw const CredentialsFormatException(
        'this credential file needs a passphrase; run it from a terminal, or '
        're-key it with a raw key (`onvif credentials key rotate --key-file`)',
      );
    }
    final passphrase = await promptSecret('Passphrase: ');
    return BundleFile(
      await openBundle(decoded, passphrase: passphrase),
      encrypted: true,
    );
  }

  /// Seals [bundle] into [path] atomically and returns the key id used.
  static Future<String> writeBundle(
    String path,
    DeviceBundle bundle, {
    String? keyFile,
    bool usePassphrase = false,
    String? passphrase,
    Map<String, String>? environment,
  }) async {
    final Map<String, dynamic> sealed;
    if (usePassphrase) {
      final secret = passphrase ?? await promptSecret('New passphrase: ');
      sealed = await sealBundle(bundle, passphrase: secret);
    } else {
      final key = await _keyFromProviders(
        keyFile: keyFile,
        env: environment ?? Platform.environment,
      );
      if (key == null) throw _missingKey();
      sealed = await sealBundle(bundle, key: key);
    }

    await _writeAtomic(path, const JsonEncoder.withIndent(' ').convert(sealed));
    return sealed['kid'] as String;
  }

  /// Returns the current key id, creating and storing a key when none exists.
  ///
  /// This is what `credentials init`/`migrate` use so the operator is not
  /// forced through a separate `key init` step; `initKey` keeps its stricter
  /// "fail if a key already exists" semantics for explicit provisioning.
  static Future<String> ensureKey({
    String? keyFile,
    Map<String, String>? environment,
  }) async {
    if (keyFile == null || File(keyFile).existsSync()) {
      final existing = await _keyFromProviders(
        keyFile: keyFile,
        env: environment ?? Platform.environment,
      );
      if (existing != null) return kidOf(existing);
    }
    final key = generateKey();
    await _storeKey(key, keyFile: keyFile);
    return kidOf(key);
  }

  /// Generates the first key and stores it in the keychain (or [keyFile]).
  static Future<String> initKey({
    String? keyFile,
    Map<String, String>? environment,
  }) async {
    // A key file that does not exist yet is the normal "first init" state, not
    // a provider failure, so it is skipped instead of raising.
    final existing = keyFile != null && !File(keyFile).existsSync()
        ? null
        : await _keyFromProviders(
            keyFile: keyFile,
            env: environment ?? Platform.environment,
          );
    if (existing != null) {
      throw CredentialsFormatException(
        'a key already exists (kid ${kidOf(existing)}); use `credentials key '
        'rotate` to replace it',
      );
    }
    final key = generateKey();
    await _storeKey(key, keyFile: keyFile);
    return kidOf(key);
  }

  /// Generates a replacement key. The caller re-seals the bundle afterwards.
  static Future<String> rotateKey({String? keyFile}) async {
    final key = generateKey();
    await _storeKey(key, keyFile: keyFile);
    return kidOf(key);
  }

  /// Reads a secret from the terminal without echoing it.
  ///
  /// `echoMode` only exists for terminals: a pipe (CI, `| onvif …`) has no echo
  /// to suppress, and touching it there throws, so it is guarded.
  static Future<String> promptSecret(String label) async {
    stdout.write(label);
    final interactive = stdin.hasTerminal;
    final wasEchoing = interactive ? stdin.echoMode : true;
    if (interactive) stdin.echoMode = false;
    try {
      final line = stdin.readLineSync() ?? '';
      if (interactive) stdout.writeln();
      if (line.isEmpty) {
        throw const CredentialsFormatException('no input; aborted');
      }
      return line;
    } finally {
      if (interactive) stdin.echoMode = wasEchoing;
    }
  }

  /// The device described by `ONVIF_HOST/USERNAME/PASSWORD`, when all three are
  /// set. A partial set is an error: mixing an ambient host with a bundle
  /// device silently would be worse than refusing.
  static DeviceEntry? _environmentDevice(Map<String, String> env) {
    final values = {
      'ONVIF_HOST': env[_hostEnv],
      'ONVIF_USERNAME': env[_userEnv],
      'ONVIF_PASSWORD': env[_passwordEnv],
    };
    final present = values.values.where((v) => v != null && v.isNotEmpty);
    if (present.isEmpty) return null;
    final missing = values.entries.where(
      (e) => e.value == null || e.value!.isEmpty,
    );
    if (missing.isNotEmpty) {
      throw CredentialsFormatException(
        'these environment variables must be set together; missing: '
        '${missing.map((e) => e.key).join(', ')}',
      );
    }
    return DeviceEntry(
      id: 'env',
      host: values['ONVIF_HOST']!,
      username: values['ONVIF_USERNAME']!,
      password: values['ONVIF_PASSWORD']!,
    );
  }

  /// Provider chain: key file (flag, then `ONVIF_KEY_FILE`), `ONVIF_KEY`, then
  /// the OS keychain. The passphrase prompt is the caller's decision because it
  /// needs a TTY.
  static Future<List<int>?> _keyFromProviders({
    String? keyFile,
    required Map<String, String> env,
  }) async {
    final filePath = keyFile ?? env[keyFileEnv];
    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw CredentialsFormatException('key file not found: $filePath');
      }
      _warnIfLoose(file);
      return parseKeyMaterial(await file.readAsString());
    }

    final fromEnv = env[keyEnv];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return parseKeyMaterial(fromEnv);
    }

    final stored = await _keychainRead();
    if (stored != null && stored.trim().isNotEmpty) {
      return parseKeyMaterial(stored);
    }
    return null;
  }

  static Future<void> _storeKey(List<int> key, {String? keyFile}) async {
    final material = base64.encode(key);
    if (keyFile != null) {
      await _writeAtomic(keyFile, '$material\n');
      return;
    }
    final stored = await _keychainStore(material);
    if (!stored) {
      throw const KeyUnavailableException(
        'no OS keychain available (install libsecret on Linux). Re-run with '
        '--key-file <path>, or export $keyEnv',
      );
    }
  }

  static KeyUnavailableException _missingKey() => const KeyUnavailableException(
    'no key found. Providers tried: --key-file, $keyFileEnv, $keyEnv, the OS '
    'keychain. Create one with `onvif credentials key init`',
  );

  static Map<String, dynamic> _decodeObject(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const CredentialsFormatException(
        'credential file is not an object',
      );
    }
    return decoded;
  }

  /// Writes via a sibling temp file and `rename`, with mode 0600 on POSIX.
  static Future<void> _writeAtomic(String path, String contents) async {
    final target = File(path);
    await target.parent.create(recursive: true);
    final tmp = File('$path.tmp');
    await tmp.writeAsString(contents, flush: true);
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', tmp.path]);
    }
    await tmp.rename(path);
  }

  static void _warnIfLoose(File file) {
    if (Platform.isWindows) return;
    final mode = file.statSync().mode & 0x1FF;
    if (mode & 0x077 != 0) {
      stderr.writeln(
        'warning: ${file.path} is accessible to other users '
        '(mode ${mode.toRadixString(8)}); tighten it with chmod 600',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// OS keychain
// ---------------------------------------------------------------------------

Future<String?> _keychainRead() async {
  if (Platform.isMacOS) {
    final result = await Process.run('security', [
      'find-generic-password',
      '-s',
      _keychainService,
      '-a',
      _keychainAccount,
      '-w',
    ]);
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  }
  if (Platform.isLinux) {
    final result = await Process.run('secret-tool', [
      'lookup',
      'service',
      _keychainService,
      'account',
      _keychainAccount,
    ]);
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  }
  if (Platform.isWindows) return _dpapiRead();
  return null;
}

Future<bool> _keychainStore(String secret) async {
  if (Platform.isMacOS) {
    // The secret is an argument here because `security` offers no stdin form;
    // it is visible to same-user processes for the lifetime of the call.
    final result = await Process.run('security', [
      'add-generic-password',
      '-U',
      '-s',
      _keychainService,
      '-a',
      _keychainAccount,
      '-w',
      secret,
    ]);
    return result.exitCode == 0;
  }
  if (Platform.isLinux) {
    final process = await Process.start('secret-tool', [
      'store',
      '--label',
      _keychainService,
      'service',
      _keychainService,
      'account',
      _keychainAccount,
    ]);
    process.stdin.write(secret);
    await process.stdin.close();
    return await process.exitCode == 0;
  }
  if (Platform.isWindows) return _dpapiStore(secret);
  return false;
}

// Windows has no keychain CLI that can *read* a secret, so the key is stored as
// a DPAPI-protected blob under %APPDATA%. Only exercised on Windows.
// ponytail: DPAPI-via-PowerShell, not FFI; swap to FFI if it measurably matters.
File get _dpapiFile => File(
  '${Platform.environment['APPDATA'] ?? '.'}'
  '${Platform.pathSeparator}easy_onvif'
  '${Platform.pathSeparator}key.dpapi',
);

Future<String?> _dpapiRead() async {
  if (!_dpapiFile.existsSync()) return null;
  final script =
      r'$ErrorActionPreference="Stop";'
      r'$p=[Convert]::FromBase64String((Get-Content -Raw $env:EASY_ONVIF_DPAPI_FILE));'
      r'$b=[Security.Cryptography.ProtectedData]::Unprotect($p,$null,"CurrentUser");'
      r'[Text.Encoding]::UTF8.GetString($b)';
  final result = await Process.run(
    'powershell',
    ['-NoProfile', '-NonInteractive', '-Command', script],
    environment: {'EASY_ONVIF_DPAPI_FILE': _dpapiFile.path},
  );
  return result.exitCode == 0 ? (result.stdout as String).trim() : null;
}

Future<bool> _dpapiStore(String secret) async {
  await _dpapiFile.parent.create(recursive: true);
  final script =
      r'$ErrorActionPreference="Stop";'
      r'$k=[Console]::In.ReadLine();'
      r'$b=[Text.Encoding]::UTF8.GetBytes($k);'
      r'$p=[Security.Cryptography.ProtectedData]::Protect($b,$null,"CurrentUser");'
      r'[IO.File]::WriteAllText($env:EASY_ONVIF_DPAPI_FILE,[Convert]::ToBase64String($p))';
  final process = await Process.start(
    'powershell',
    ['-NoProfile', '-NonInteractive', '-Command', script],
    environment: {'EASY_ONVIF_DPAPI_FILE': _dpapiFile.path},
  );
  process.stdin.write('$secret\n');
  await process.stdin.close();
  return await process.exitCode == 0;
}
