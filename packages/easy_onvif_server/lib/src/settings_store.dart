import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'settings.dart';

/// Persists [ServerSettings] as pretty-printed JSON in the app's own storage
/// (Application Support on macOS, so no sandbox entitlement is needed).
///
/// A corrupt or missing file never blocks startup: [load] falls back to
/// defaults and the next [save] overwrites the bad file.
class SettingsStore {
  /// Overrides the platform storage directory (used by tests, which have no
  /// path_provider platform channel).
  final String? directoryOverride;

  const SettingsStore({this.directoryOverride});

  Future<File> _file() async {
    final directory =
        directoryOverride ?? (await getApplicationSupportDirectory()).path;

    return File('$directory/settings.json');
  }

  /// Reads the persisted settings, or defaults when the file is missing or
  /// unparseable. File I/O is synchronous so the store also works under
  /// flutter_test's fake-async zone (real I/O futures never complete there).
  Future<ServerSettings> load() async {
    try {
      final file = await _file();

      if (!file.existsSync()) return const ServerSettings();

      final decoded = jsonDecode(file.readAsStringSync());

      if (decoded is! Map) return const ServerSettings();

      return ServerSettings.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      return const ServerSettings();
    } on IOException {
      return const ServerSettings();
    }
  }

  /// Writes [settings] atomically (temp file + rename) so a crash mid-write
  /// never leaves a truncated settings file behind.
  Future<void> save(ServerSettings settings) async {
    final file = await _file();

    file.parent.createSync(recursive: true);

    final temp = File('${file.path}.tmp');

    temp.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      flush: true,
    );
    temp.renameSync(file.path);
  }
}
