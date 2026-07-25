import 'dart:collection';

import 'package:loggy/loggy.dart';

/// A [LoggyPrinter] decorator that keeps the last [capacity] formatted log
/// lines in memory so `GetSystemLog` can return real device logs.
class BufferedLoggyPrinter extends LoggyPrinter {
  final LoggyPrinter inner;
  final int capacity;

  static final Queue<String> _lines = Queue<String>();
  static int _capacity = 200;

  BufferedLoggyPrinter(this.inner, {this.capacity = 200}) {
    _capacity = capacity;
  }

  @override
  void onLog(LogRecord record) {
    inner.onLog(record);

    _lines.addLast(
      '${record.time.toIso8601String()} '
      '${record.level.name.toUpperCase()} ${record.message}',
    );

    while (_lines.length > _capacity) {
      _lines.removeFirst();
    }
  }

  /// The buffered log lines, oldest first.
  static List<String> get lines => List.unmodifiable(_lines);
}
