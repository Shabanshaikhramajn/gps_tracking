import 'dart:developer' as developer;

// Thin dart:developer.log() wrapper, used everywhere instead of print().
// Pass a "name" per call site (e.g. 'LocationRepository') to filter logs.
class AppLogger {
  const AppLogger._();

  static const String _defaultName = 'GpsTracker';

  // Routine, detailed tracing - "a fix was captured", "a row was read".
  static void debug(String message, {String name = _defaultName}) {
    developer.log(message, name: name, level: 500);
  }

  // Notable but expected events - "tracking started", "sync finished".
  static void info(String message, {String name = _defaultName}) {
    developer.log(message, name: name, level: 800);
  }

  // Worth a second look but not a hard failure - "sync attempt failed".
  static void warning(String message, {String name = _defaultName}) {
    developer.log(message, name: name, level: 900);
  }

  // An actual error. Pass the caught exception/stack trace through too.
  static void error(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
