import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/config.dart';
import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/settings_store.dart';

void main() {
  late Directory tempDir;
  late SettingsStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('settings_store_test');
    store = SettingsStore(directoryOverride: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('load returns defaults when no file exists', () async {
    final settings = await store.load();

    expect(settings.config.httpPort, 8080);
    expect(settings.media.audioEnabled, isFalse);
  });

  test('save then load round-trips', () async {
    const settings = ServerSettings(
      config: ServerConfig(httpPort: 9080, username: 'operator'),
      media: MediaSettings(audioEnabled: true, audioDevice: 'BuiltInMic'),
      segmentSeconds: 4,
    );

    await store.save(settings);

    final loaded = await store.load();

    expect(loaded.config.httpPort, 9080);
    expect(loaded.config.username, 'operator');
    expect(loaded.media.audioEnabled, isTrue);
    expect(loaded.media.audioDevice, 'BuiltInMic');
    expect(loaded.segmentSeconds, 4);
  });

  test('save writes readable pretty-printed json', () async {
    await store.save(const ServerSettings());

    final content = File('${tempDir.path}/settings.json').readAsStringSync();
    final decoded = jsonDecode(content) as Map<String, Object?>;

    expect(content, contains('\n'));
    expect(decoded['network'], isA<Map<String, Object?>>());
    expect(decoded['media'], isA<Map<String, Object?>>());
  });

  test('corrupt file falls back to defaults', () async {
    File('${tempDir.path}/settings.json').writeAsStringSync('{not json!');

    final settings = await store.load();

    expect(settings.config.httpPort, 8080);
  });

  test('non-object json falls back to defaults', () async {
    File('${tempDir.path}/settings.json').writeAsStringSync('[1, 2, 3]');

    final settings = await store.load();

    expect(settings.config.httpPort, 8080);
  });

  test('save leaves no temp file behind', () async {
    await store.save(const ServerSettings());

    final leftovers = tempDir
        .listSync()
        .map((entity) => entity.path.split('/').last)
        .toList();

    expect(leftovers, ['settings.json']);
  });

  test('save overwrites a corrupt file', () async {
    final file = File('${tempDir.path}/settings.json')
      ..writeAsStringSync('garbage');

    await store.save(
      const ServerSettings(config: ServerConfig(httpPort: 9090)),
    );

    final loaded = await store.load();

    expect(loaded.config.httpPort, 9090);
    expect(file.readAsStringSync(), contains('9090'));
  });
}
