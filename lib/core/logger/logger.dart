import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  final String tag;
  final LogLevel minLevel;

  const Logger({this.tag = 'Sumi', this.minLevel = LogLevel.debug});

  void debug(String message, [Object? error, StackTrace? stack]) =>
      _log(LogLevel.debug, message, error, stack);

  void info(String message, [Object? error, StackTrace? stack]) =>
      _log(LogLevel.info, message, error, stack);

  void warning(String message, [Object? error, StackTrace? stack]) =>
      _log(LogLevel.warning, message, error, stack);

  void error(String message, [Object? error, StackTrace? stack]) =>
      _log(LogLevel.error, message, error, stack);

  void _log(LogLevel level, String message, [Object? error, StackTrace? stack]) {
    if (level.index < minLevel.index) return;
    final prefix = _prefix(level);
    final line = '$prefix [$tag] $message';
    if (error != null) {
      debugPrint('$line\n$error');
    } else {
      debugPrint(line);
    }
    if (stack != null && level == LogLevel.error) {
      debugPrint(stack.toString());
    }
  }

  String _prefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return '🔍';
      case LogLevel.info: return 'ℹ️';
      case LogLevel.warning: return '⚠️';
      case LogLevel.error: return '❌';
    }
  }
}
