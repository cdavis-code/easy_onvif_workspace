import 'dart:convert';
import 'dart:io';

/// One `.h264` segment of a recording.
///
/// A segment is a raw Annex-B H.264 elementary stream that starts with an IDR
/// frame, so replay can begin at any segment boundary.
class RecordingSegment {
  final String file;
  final DateTime startUtc;
  DateTime endUtc;
  int frameCount;

  RecordingSegment({
    required this.file,
    required this.startUtc,
    required this.endUtc,
    this.frameCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'file': file,
    'startUtc': startUtc.toIso8601String(),
    'endUtc': endUtc.toIso8601String(),
    'frameCount': frameCount,
  };

  factory RecordingSegment.fromJson(Map<String, dynamic> json) =>
      RecordingSegment(
        file: json['file'] as String,
        startUtc: DateTime.parse(json['startUtc'] as String),
        endUtc: DateTime.parse(json['endUtc'] as String),
        frameCount: json['frameCount'] as int? ?? 0,
      );
}

/// The on-disk metadata for a single recording (persisted as `index.json`
/// alongside the segment files in the recording's directory).
class RecordingIndex {
  final String recordingToken;
  final Directory directory;
  final DateTime createdUtc;
  final int frameRate;
  final String sourceToken;
  final String profileToken;
  final List<RecordingSegment> segments;

  RecordingIndex({
    required this.recordingToken,
    required this.directory,
    required this.createdUtc,
    required this.frameRate,
    required this.sourceToken,
    required this.profileToken,
    List<RecordingSegment>? segments,
  }) : segments = segments ?? [];

  /// The start of the earliest segment, or `null` when nothing was recorded.
  DateTime? get earliestUtc => segments.isEmpty ? null : segments.first.startUtc;

  /// The end of the latest segment, or `null` when nothing was recorded.
  DateTime? get latestUtc => segments.isEmpty ? null : segments.last.endUtc;

  File get indexFile => File('${directory.path}/index.json');

  File segmentFile(RecordingSegment segment) =>
      File('${directory.path}/${segment.file}');

  Future<void> save() async {
    // Write-then-rename so a crash mid-write cannot leave a torn index that
    // would orphan the recording's segments on the next load.
    final tmp = File('${indexFile.path}.tmp');

    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'recordingToken': recordingToken,
        'createdUtc': createdUtc.toIso8601String(),
        'frameRate': frameRate,
        'sourceToken': sourceToken,
        'profileToken': profileToken,
        'segments': segments.map((s) => s.toJson()).toList(),
      }),
    );

    await tmp.rename(indexFile.path);
  }

  static Future<RecordingIndex?> load(Directory directory) async {
    final file = File('${directory.path}/index.json');

    if (!file.existsSync()) return null;

    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      return RecordingIndex(
        recordingToken: json['recordingToken'] as String,
        directory: directory,
        createdUtc: DateTime.parse(json['createdUtc'] as String),
        frameRate: json['frameRate'] as int? ?? 15,
        sourceToken: json['sourceToken'] as String? ?? 'VideoSource_1',
        profileToken: json['profileToken'] as String? ?? 'Profile_1',
        segments: [
          for (final s in (json['segments'] as List? ?? []))
            RecordingSegment.fromJson(s as Map<String, dynamic>),
        ],
      );
    } catch (_) {
      // A corrupt index is skipped rather than crashing startup.
      return null;
    }
  }
}
