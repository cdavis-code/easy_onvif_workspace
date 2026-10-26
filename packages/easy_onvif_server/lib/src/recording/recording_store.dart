import 'dart:io';

import 'recording_index.dart';

/// Owns the recordings directory: loads existing recordings at startup,
/// creates/deletes recording directories, and applies retention pruning.
class RecordingStore {
  final Directory root;
  final int? maxRetentionMinutes;

  final Map<String, RecordingIndex> _recordings = {};

  RecordingStore({required this.root, this.maxRetentionMinutes});

  List<RecordingIndex> get recordings => _recordings.values.toList();

  RecordingIndex? byToken(String token) => _recordings[token];

  /// Loads all recordings found under [root] (recordings survive restarts).
  Future<void> open() async {
    if (!root.existsSync()) await root.create(recursive: true);

    await for (final entry in root.list()) {
      if (entry is Directory) {
        final index = await RecordingIndex.load(entry);

        if (index != null) _recordings[index.recordingToken] = index;
      }
    }
  }

  Future<RecordingIndex> create({
    required String recordingToken,
    required int frameRate,
    required String sourceToken,
    required String profileToken,
  }) async {
    final directory = Directory('${root.path}/$recordingToken');

    await directory.create(recursive: true);

    final index = RecordingIndex(
      recordingToken: recordingToken,
      directory: directory,
      createdUtc: DateTime.now().toUtc(),
      frameRate: frameRate,
      sourceToken: sourceToken,
      profileToken: profileToken,
    );

    await index.save();

    _recordings[recordingToken] = index;

    return index;
  }

  Future<void> delete(String recordingToken) async {
    final index = _recordings.remove(recordingToken);

    if (index != null && index.directory.existsSync()) {
      await index.directory.delete(recursive: true);
    }
  }

  /// Drops segments older than the retention window (called on rotation).
  Future<void> prune(RecordingIndex index) async {
    final retention = maxRetentionMinutes;

    if (retention == null) return;

    final cutoff = DateTime.now().toUtc().subtract(
      Duration(minutes: retention),
    );

    while (index.segments.length > 1 &&
        index.segments.first.endUtc.isBefore(cutoff)) {
      final segment = index.segments.removeAt(0);
      final file = index.segmentFile(segment);

      if (file.existsSync()) await file.delete();

      final audio = index.audioFile(segment);

      if (audio != null && audio.existsSync()) await audio.delete();
    }

    await index.save();
  }
}
