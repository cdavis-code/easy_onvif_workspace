import 'dart:collection';

import 'package:loggy/loggy.dart';

/// A [LoggyPrinter] decorator that keeps the last [capacity] formatted log
/// lines in memory so `GetSystemLog` can return real device logs.
class BufferedLoggyPrinter extends LoggyPrinter {
  final LoggyPrinter inner;
  final int capacity;

  final Queue<String> _lines = Queue<String>();

  BufferedLoggyPrinter(this.inner, {this.capacity = 200});

  @override
  void onLog(LogRecord record) {
    inner.onLog(record);

    _lines.addLast(
      _sanitize(
        '${record.time.toIso8601String()} '
        '${record.level.name.toUpperCase()} ${record.message}',
      ),
    );

    while (_lines.length > capacity) {
      _lines.removeFirst();
    }
  }

  /// The buffered log lines, oldest first.
  List<String> get lines => List.unmodifiable(_lines);

  /// Restricts a line to printable ASCII (plus tab) so the buffered text can
  /// be embedded verbatim in an MTOM part: the `easy_onvif` client decodes
  /// parts bytewise and splits them on any `\r\n--` sequence, so control and
  /// non-ASCII characters would corrupt the transfer.
  static String _sanitize(String line) =>
      line.replaceAll(RegExp(r'[^\x09\x20-\x7E]'), ' ');
}
