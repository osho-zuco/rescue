import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Logger Service
///
/// Simple logging utility with environment-aware output.
/// Logs are only printed in debug/development mode.
///
/// Usage:
/// ```dart
/// LoggerService.d('Debug message');
/// LoggerService.i('Info message');
/// LoggerService.w('Warning message');
/// LoggerService.e('Error message', error, stackTrace);
/// ```
class LoggerService {
  LoggerService._();

  /// Debug log
  static void d(String message, [String? tag]) {
    _log('DEBUG', message, tag);
  }

  /// Info log
  static void i(String message, [String? tag]) {
    _log('INFO', message, tag);
  }

  /// Warning log
  static void w(String message, [String? tag]) {
    _log('WARN', message, tag);
  }

  /// Error log
  static void e(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    _log('ERROR', message, tag);
    if (error != null) {
      _log('ERROR', 'Error: $error', tag);
    }
    if (stackTrace != null && (kDebugMode || EnvConfig.instance.environment == Environment.dev)) {
      _log('ERROR', 'StackTrace: $stackTrace', tag);
    }
  }

  /// Internal log method
  static void _log(String level, String message, String? tag) {
    // Only log in debug mode or development
    if (!kDebugMode && !(EnvConfig.instance.environment == Environment.dev)) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final tagStr = tag != null ? '[$tag]' : '';
    final logMessage = '$timestamp [$level]$tagStr $message';

    // Use debugPrint for longer messages (handles truncation)
    debugPrint(logMessage);
  }
}

/// Shorthand for LoggerService
typedef Log = LoggerService;
