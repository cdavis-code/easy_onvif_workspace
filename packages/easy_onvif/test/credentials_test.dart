/// Credential bundle tests: envelope round-trips, tamper detection, KDF
/// behaviour, legacy compatibility, provider precedence and keychain presence.
///
/// The XML fixture tests next door need an out-of-tree `test_data` checkout;
/// this file is hermetic and runs anywhere.
library;

import 'dart:convert';
import 'dart:io';

import 'package:easy_onvif/credentials.dart';
import 'package:test/test.dart';

const _entry = DeviceEntry(
  id: 'cam-lobby',
  name: 'Lobby',
  site: 'plant-a',
  host: '192.168.1.10:8080',
  username: 'operator',
  password: 'correct horse battery staple',
  tags: ['entrance'],
);

DeviceBundle get _bundle => DeviceBundle.single(_entry);

void main() {
  group('envelope', () {
    test('round-trips a bundle for raw, hex and base64 keys', () async {
      final key = generateKey();
      for (final material in [
        key,
        parseKeyMaterial(generateKey().map(_hex).join()),
        parseKeyMaterial(base64.encode(generateKey())),
      ]) {
        final sealed = await sealBundle(_bundle, key: material);
        final opened = await openBundle(sealed, key: material);
        expect(opened.toJson(), _bundle.toJson());
        expect(sealed['kid'], kidOf(material));
        expect(sealed['kdf'], kdfNone);
      }
    });

    test('rejects a flipped ciphertext byte', () async {
      final key = generateKey();
      final sealed = await sealBundle(_bundle, key: key);
      final raw = base64.decode(sealed['ct'] as String);
      raw[0] ^= 0xFF;
      sealed['ct'] = base64.encode(raw);

      await expectLater(
        openBundle(sealed, key: key),
        throwsA(isA<CredentialsFormatException>()),
      );
    });

    test('rejects tampered header fields (authenticated as AAD)', () async {
      final key = generateKey();
      final sealed = await sealBundle(_bundle, key: key);

      for (final field in ['alg', 'kid', 'kdf', 'v']) {
        final copy = Map<String, dynamic>.from(sealed);
        copy[field] = field == 'v' ? 99 : 'tampered';
        await expectLater(
          openBundle(copy, key: key),
          throwsA(isA<CredentialsFormatException>()),
          reason: 'flipping $field must invalidate the envelope',
        );
      }
    });

    test('a wrong key is reported with both key ids', () async {
      final sealed = await sealBundle(_bundle, key: generateKey());
      final wrong = generateKey();

      await expectLater(
        openBundle(sealed, key: wrong),
        throwsA(
          isA<CredentialsFormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains(sealed['kid'] as String), contains(kidOf(wrong))),
          ),
        ),
      );
    });
  });

  group('argon2id', () {
    test('is deterministic per salt and differs across salts', () async {
      final salt = KdfSpec.random().salt;
      final a = await KdfSpec(salt: salt).derive('hunter2');
      final b = await KdfSpec(salt: salt).derive('hunter2');
      final c = await KdfSpec.random().derive('hunter2');

      expect(a, b);
      expect(a, isNot(c));
      expect(a.length, keyLength);
    });

    test('parameters round-trip through the kdf string', () {
      final spec = KdfSpec(salt: List<int>.filled(16, 7), memory: 4096);
      final parsed = KdfSpec.parse(spec.format());

      expect(parsed.memory, 4096);
      expect(parsed.iterations, spec.iterations);
      expect(parsed.salt, spec.salt);
      expect(parsed.format(), spec.format());
    });

    test(
      'a passphrase-sealed bundle opens with the same passphrase only',
      () async {
        final sealed = await sealBundle(_bundle, passphrase: 'hunter2');
        expect(sealed['kdf'], startsWith('argon2id:'));

        expect((await openBundle(sealed, passphrase: 'hunter2')).ids, [
          'cam-lobby',
        ]);
        await expectLater(
          openBundle(sealed, passphrase: 'wrong'),
          throwsA(isA<CredentialsFormatException>()),
        );
      },
    );
  });

  group('bundle', () {
    test('reads the legacy single-device shape as device "default"', () {
      final legacy = DeviceBundle.legacy({
        'host': '10.0.0.5',
        'username': 'admin',
        'password': 'pw',
      });

      expect(legacy.ids, ['default']);
      expect(legacy.resolve().host, '10.0.0.5');
    });

    test('resolves by id, default, and errors listing the alternatives', () {
      final bundle = DeviceBundle(
        devices: [
          _entry,
          const DeviceEntry(
            id: 'cam-gate',
            host: '10.0.0.9',
            username: 'admin',
            password: 'pw',
          ),
        ],
        defaultId: 'cam-lobby',
      );

      expect(bundle.resolve().id, 'cam-lobby');
      expect(bundle.resolve('cam-gate').id, 'cam-gate');
      expect(
        () => bundle.resolve('nope'),
        throwsA(
          isA<CredentialsFormatException>().having(
            (e) => e.message,
            'message',
            contains('cam-gate'),
          ),
        ),
      );
      expect(bundle.matching(site: 'plant-a').map((d) => d.id), ['cam-lobby']);
    });

    test('rejects duplicate ids', () {
      expect(
        () => DeviceBundle.fromJson({
          'devices': [_entry.toJson(), _entry.toJson()],
        }),
        throwsA(isA<CredentialsFormatException>()),
      );
    });
  });

  group('store', () {
    late Directory dir;
    late String bundlePath;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('onvif_creds_test');
      bundlePath = '${dir.path}/credentials.json';
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('writes and re-reads an encrypted file with a key file', () async {
      final keyPath = '${dir.path}/key';
      final kid = await CredentialStore.initKey(keyFile: keyPath);

      final writtenKid = await CredentialStore.writeBundle(
        bundlePath,
        _bundle,
        keyFile: keyPath,
        environment: const {},
      );
      expect(writtenKid, kid);

      final file = await CredentialStore.readBundle(
        bundlePath,
        keyFile: keyPath,
        environment: const {},
      );
      expect(file.encrypted, isTrue);
      expect(file.bundle.ids, ['cam-lobby']);

      if (!Platform.isWindows) {
        final mode = File(bundlePath).statSync().mode & 0x1FF;
        expect(
          mode & 0x077,
          0,
          reason: 'file must not be group/world readable',
        );
      }
    });

    test('provider precedence: explicit key file beats ONVIF_KEY', () async {
      final keyPath = '${dir.path}/key';
      await CredentialStore.initKey(keyFile: keyPath);
      await CredentialStore.writeBundle(
        bundlePath,
        _bundle,
        keyFile: keyPath,
        environment: const {},
      );

      final env = {
        CredentialStoreKey.env: base64.encode(generateKey()), // wrong key
        CredentialStoreKey.keyFile: keyPath, // right key
      };
      final file = await CredentialStore.readBundle(
        bundlePath,
        environment: env,
      );
      expect(file.bundle.ids, ['cam-lobby']);
    });

    test('a missing key fails closed with the provider list', () async {
      if (await _keychainHasKey()) {
        // Provider 3 would legitimately satisfy the read, so "no key at all"
        // is not reachable on this machine.
        markTestSkipped('this machine has an easy_onvif keychain entry');
        return;
      }
      final keyPath = '${dir.path}/key';
      await CredentialStore.initKey(keyFile: keyPath);
      await CredentialStore.writeBundle(
        bundlePath,
        _bundle,
        keyFile: keyPath,
        environment: const {},
      );

      await expectLater(
        CredentialStore.readBundle(bundlePath, environment: const {}),
        throwsA(
          isA<KeyUnavailableException>().having(
            (e) => e.message,
            'message',
            contains('credentials key init'),
          ),
        ),
      );
    });

    test('ONVIF_HOST/USERNAME/PASSWORD must be set together', () async {
      await expectLater(
        CredentialStore.resolveDevice(
          bundlePath,
          environment: const {'ONVIF_HOST': '10.0.0.1'},
        ),
        throwsA(
          isA<CredentialsFormatException>().having(
            (e) => e.message,
            'message',
            contains('ONVIF_USERNAME'),
          ),
        ),
      );
    });

    test('environment device wins over a bundle', () async {
      final device = await CredentialStore.resolveDevice(
        bundlePath, // does not exist on purpose
        environment: const {
          'ONVIF_HOST': '10.0.0.1',
          'ONVIF_USERNAME': 'admin',
          'ONVIF_PASSWORD': 'pw',
        },
      );
      expect(device.id, 'env');
      expect(device.host, '10.0.0.1');
    });

    test(
      'legacy plaintext is read, then migrate leaves only ciphertext',
      () async {
        File(bundlePath).writeAsStringSync(
          jsonEncode({
            'host': '10.0.0.5',
            'username': 'admin',
            'password': 'pw',
          }),
        );

        final before = await CredentialStore.readBundle(
          bundlePath,
          environment: const {},
        );
        expect(before.encrypted, isFalse);
        expect(before.bundle.ids, ['default']);

        final keyPath = '${dir.path}/key';
        await CredentialStore.initKey(keyFile: keyPath);
        await CredentialStore.writeBundle(
          '$bundlePath.enc',
          before.bundle,
          keyFile: keyPath,
          environment: const {},
        );
        File(bundlePath).deleteSync();

        final after = await CredentialStore.readBundle(
          '$bundlePath.enc',
          keyFile: keyPath,
          environment: const {},
        );
        expect(after.encrypted, isTrue);
        expect(after.bundle.ids, ['default']);
        expect(File(bundlePath).existsSync(), isFalse);
        expect(
          File('$bundlePath.enc').readAsStringSync(),
          isNot(contains('"password"')),
          reason: 'ciphertext must not embed the plaintext key names',
        );
      },
    );

    test(
      'OS keychain round-trip (skipped when the OS tool is absent)',
      () async {
        final available = await _keychainAvailable();
        if (!available) {
          markTestSkipped('no OS keychain tool on this machine');
          return;
        }
        final kid = await CredentialStore.initKey();
        final written = await CredentialStore.writeBundle(
          bundlePath,
          _bundle,
          environment: const {},
        );
        expect(written, kid);
        final file = await CredentialStore.readBundle(
          bundlePath,
          environment: const {},
        );
        expect(file.bundle.ids, ['cam-lobby']);
      },
      // Opt-in only: this writes a real keychain entry, which a routine test
      // run must never do on the operator's machine.
      skip: Platform.environment['ONVIF_TEST_KEYCHAIN'] == '1'
          ? _keychainSkipReason()
          : 'set ONVIF_TEST_KEYCHAIN=1 to exercise the real keychain',
    );
  });
}

String _hex(int byte) => byte.toRadixString(16).padLeft(2, '0');

/// The provider env names, re-exported here so the test does not import the
/// internal `store_io.dart` file just for two constants.
abstract final class CredentialStoreKey {
  static const String env = 'ONVIF_KEY';
  static const String keyFile = 'ONVIF_KEY_FILE';
}

Future<bool> _keychainAvailable() async {
  if (Platform.isMacOS) {
    final result = await _tryRun('security', ['-h']);
    return result != null && (result.exitCode == 0 || result.exitCode == 1);
  }
  if (Platform.isLinux) {
    final result = await _tryRun('secret-tool', ['--version']);
    return result != null && result.exitCode == 0;
  }
  return false;
}

/// "Not installed" is not an error here: it just means no keychain.
Future<ProcessResult?> _tryRun(String exe, List<String> args) async {
  try {
    return await Process.run(exe, args);
  } on ProcessException {
    return null;
  }
}

Future<bool> _keychainHasKey() async {
  if (Platform.isMacOS) {
    final result = await _tryRun('security', [
      'find-generic-password',
      '-s',
      'easy_onvif',
      '-a',
      'easy_onvif',
    ]);
    return result != null && result.exitCode == 0;
  }
  if (Platform.isLinux) {
    final result = await _tryRun('secret-tool', [
      'lookup',
      'service',
      'easy_onvif',
      'account',
      'easy_onvif',
    ]);
    return result != null &&
        result.exitCode == 0 &&
        (result.stdout as String).trim().isNotEmpty;
  }
  return false;
}

String? _keychainSkipReason() {
  if (Platform.isMacOS || Platform.isLinux) return null;
  return 'keychain providers are macOS/Linux only in this test';
}
