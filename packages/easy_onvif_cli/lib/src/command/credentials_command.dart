import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:easy_onvif/credentials.dart';

/// `onvif credentials …` — the encrypted, multi-device credential bundle.
class OnvifCredentialsCommand extends Command<void> {
  OnvifCredentialsCommand() {
    addSubcommand(_InitCommand());
    addSubcommand(_AddCommand());
    addSubcommand(_RemoveCommand());
    addSubcommand(_ListCommand());
    addSubcommand(_DefaultCommand());
    addSubcommand(_MigrateCommand());
    addSubcommand(_KeyCommand());
  }

  @override
  String get name => 'credentials';

  @override
  String get description =>
      'Manage encrypted device credentials (add, remove, list, migrate, keys).';

  @override
  void run() => print(usage);
}

/// Creates the first encrypted bundle. Shared with `onvif authorize`.
Future<void> runCredentialsInit(
  ArgResults globalResults, {
  bool overwritePrompt = false,
}) async {
  final path = globalResults['config-file'] as String;
  final keyFile = globalResults['key-file'] as String?;
  final usePassphrase = globalResults['prompt'] == true;

  if (overwritePrompt && File(path).existsSync()) {
    stdout.write('Overwrite the existing credential file [y/N]: ');
    final answer = (stdin.readLineSync() ?? '').trim().toLowerCase();
    if (answer != 'y') {
      stdout.writeln('Nothing changed.');
      return;
    }
  } else if (File(path).existsSync()) {
    throw UsageException(
      '$path already exists; use `credentials add` or delete it first',
      usageOf('credentials init'),
    );
  }

  if (!usePassphrase) {
    final kid = await CredentialStore.ensureKey(keyFile: keyFile);
    stdout.writeln('Using key $kid.');
  }

  final bundle = DeviceBundle.single(await _askDevice());
  final kid = await CredentialStore.writeBundle(
    path,
    bundle,
    keyFile: keyFile,
    usePassphrase: usePassphrase,
  );
  stdout.writeln('Wrote $path sealed with $kid.');
}

class _InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Create an encrypted credential file (prompts for one device).';

  @override
  void run() async => runCredentialsInit(globalResults!);
}

class _AddCommand extends Command<void> {
  @override
  String get name => 'add';

  @override
  String get description => 'Add or replace a device in the credential file.';

  @override
  void run() async {
    final path = globalResults!['config-file'] as String;
    final keyFile = globalResults!['key-file'] as String?;
    final bundle = await _readOrEmpty(path, keyFile);

    final device = await _askDevice();
    final devices = [
      for (final existing in bundle.devices)
        if (existing.id != device.id) existing,
      device,
    ];
    await _write(
      path,
      DeviceBundle(devices: devices, defaultId: bundle.defaultId ?? device.id),
      keyFile,
    );
  }
}

class _RemoveCommand extends Command<void> {
  @override
  String get name => 'remove';

  @override
  String get description => 'Remove a device from the credential file.';

  @override
  void run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('expected exactly one device id', usage);
    }
    final path = globalResults!['config-file'] as String;
    final keyFile = globalResults!['key-file'] as String?;
    final bundle = await _readOrEmpty(path, keyFile);

    final devices = bundle.devices.where((d) => d.id != rest.single).toList();
    if (devices.length == bundle.devices.length) {
      throw UsageException('no device "${rest.single}"', usage);
    }
    if (devices.isEmpty) {
      throw UsageException('refusing to leave an empty bundle', usage);
    }

    await _write(
      path,
      DeviceBundle(
        devices: devices,
        defaultId: bundle.defaultId == rest.single
            ? devices.first.id
            : bundle.defaultId,
      ),
      keyFile,
    );
  }
}

class _ListCommand extends Command<void> {
  _ListCommand() {
    argParser
      ..addOption('site', help: 'Only devices in this site.')
      ..addOption('tag', help: 'Only devices carrying this tag.');
  }

  @override
  String get name => 'list';

  @override
  String get description =>
      'List devices (ids, names, sites, hosts; no secrets).';

  @override
  void run() async {
    final path = globalResults!['config-file'] as String;
    final keyFile = globalResults!['key-file'] as String?;
    final bundle = await _readOrEmpty(path, keyFile);

    final matches = bundle.matching(
      site: argResults!['site'] as String?,
      tag: argResults!['tag'] as String?,
    );
    for (final device in matches) {
      final marker = device.id == bundle.defaultId ? '*' : ' ';
      final site = device.site == null ? '' : ' [${device.site}]';
      stdout.writeln('$marker ${device.id}$site ${device.host}');
    }
  }
}

class _DefaultCommand extends Command<void> {
  @override
  String get name => 'default';

  @override
  String get description => 'Choose the device used when --device is omitted.';

  @override
  void run() async {
    if (argResults!.rest.length != 1) {
      throw UsageException('expected exactly one device id', usage);
    }
    final path = globalResults!['config-file'] as String;
    final keyFile = globalResults!['key-file'] as String?;
    final bundle = await _readOrEmpty(path, keyFile);

    final target = argResults!.rest.single;
    if (!bundle.ids.contains(target)) {
      throw UsageException(
        'no device "$target" (available: ${bundle.ids.join(', ')})',
        usage,
      );
    }
    await _write(
      path,
      DeviceBundle(devices: bundle.devices, defaultId: target),
      keyFile,
    );
  }
}

class _MigrateCommand extends Command<void> {
  @override
  String get name => 'migrate';

  @override
  String get description =>
      'Seal an existing plaintext credential file, then remove the plaintext.';

  @override
  void run() async {
    final path = globalResults!['config-file'] as String;
    final keyFile = globalResults!['key-file'] as String?;

    final file = await CredentialStore.readBundle(
      path,
      allowPrompt: false,
      environment: Platform.environment,
    );
    if (file.encrypted) {
      stdout.writeln('$path is already encrypted; nothing to do.');
      return;
    }

    final kid = await CredentialStore.ensureKey(keyFile: keyFile);

    // Write beside the original, verify the sealed copy opens, then rename over
    // the plaintext. The plaintext is replaced atomically and never lost on a
    // failure, and the config-file path stays valid for every command.
    final staged = '$path.migrate';
    await CredentialStore.writeBundle(
      staged,
      file.bundle,
      keyFile: keyFile,
      environment: Platform.environment,
    );
    final verified = await CredentialStore.readBundle(
      staged,
      keyFile: keyFile,
      allowPrompt: false,
      environment: Platform.environment,
    );
    if (verified.bundle.ids.join(',') != file.bundle.ids.join(',')) {
      throw StateError('verification failed for $staged; original left intact');
    }
    File(staged).renameSync(path);

    stdout.writeln('Migrated $path (key $kid). The plaintext is gone.');
  }
}

class _KeyCommand extends Command<void> {
  _KeyCommand() {
    addSubcommand(_KeyInitCommand());
    addSubcommand(_KeyRotateCommand());
  }

  @override
  String get name => 'key';

  @override
  String get description => 'Create or rotate the encryption key.';

  @override
  void run() => print(usage);
}

class _KeyInitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Generate the first key (OS keychain, or --key-file <path>).';

  @override
  void run() async {
    final kid = await CredentialStore.initKey(
      keyFile: globalResults!['key-file'] as String?,
    );
    stdout.writeln('Created key $kid.');
  }
}

class _KeyRotateCommand extends Command<void> {
  @override
  String get name => 'rotate';

  @override
  String get description =>
      'Replace the key and re-seal the credential file with it.';

  @override
  void run() async {
    final path = globalResults!['config-file'] as String;
    final keyFile = globalResults!['key-file'] as String?;

    final bundle = await _readOrEmpty(path, keyFile);
    final kid = await CredentialStore.rotateKey(keyFile: keyFile);
    await _write(path, bundle, keyFile);
    stdout.writeln('Rotated to key $kid and re-sealed $path.');
  }
}

// ---------------------------------------------------------------------------
// Shared prompts
// ---------------------------------------------------------------------------

Future<DeviceBundle> _readOrEmpty(String path, String? keyFile) async {
  if (!File(path).existsSync()) {
    throw UsageException(
      '$path does not exist; run `onvif credentials init` first',
      'onvif credentials',
    );
  }
  final file = await CredentialStore.readBundle(path, keyFile: keyFile);
  if (!file.encrypted) {
    stderr.writeln(
      'warning: $path is unencrypted; run `onvif credentials migrate`',
    );
  }
  return file.bundle;
}

Future<void> _write(String path, DeviceBundle bundle, String? keyFile) async {
  final kid = await CredentialStore.writeBundle(path, bundle, keyFile: keyFile);
  stdout.writeln('Wrote $path sealed with $kid.');
}

Future<DeviceEntry> _askDevice() async {
  final id = _ask('Device id (slug)');
  final host = _ask('Host (optionally host:port)');
  final username = _ask('Username');

  stdout.write('Password: ');
  final password = await CredentialStore.promptSecret('');
  if (password.isEmpty) {
    throw UsageException('empty password', 'onvif credentials');
  }

  stdout.write('Name (optional): ');
  final name = (stdin.readLineSync() ?? '').trim();
  stdout.write('Site (optional): ');
  final site = (stdin.readLineSync() ?? '').trim();

  return DeviceEntry(
    id: id,
    host: host,
    username: username,
    password: password,
    name: name.isEmpty ? null : name,
    site: site.isEmpty ? null : site,
  );
}

String _ask(String label) {
  stdout.write('$label: ');
  final value = (stdin.readLineSync() ?? '').trim();
  if (value.isEmpty) {
    throw UsageException('"$label" is required', 'onvif credentials');
  }
  return value;
}

/// `credentials init` usage text, for the shared init path used by `authorize`.
String usageOf(String command) => 'Usage: onvif $command';
