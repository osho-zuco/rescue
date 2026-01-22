/// Logger Service
///
/// Structured logging for the Zuco app.
/// In dev: prints to console with colors
/// In prod: sends to Sentry as breadcrumbs
///
/// Usage:
///   Log.d('Debug message');
///   Log.i('Info message');
///   Log.w('Warning message');
///   Log.e('Error message', error: e, stackTrace: s);

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Log levels
enum LogLevel { debug, info, warning, error }

/// Global logger instance
class Log {
  Log._();

  static const _enabledInRelease = false; // Set true to enable console logs in release

  /// Debug - for development only
  static void d(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// Info - general information
  static void i(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Warning - something unexpected but not fatal
  static void w(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  /// Error - something went wrong
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Internal log method
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final formattedMessage = '$tagPrefix$message';

    // Console logging (dev only, unless explicitly enabled)
    if (kDebugMode || _enabledInRelease) {
      final emoji = _levelEmoji(level);
      final coloredMessage = _colorize(level, '$emoji $formattedMessage');
      
      // ignore: avoid_print
      print('$timestamp $coloredMessage');
      
      if (error != null) {
        // ignore: avoid_print
        print('  Error: $error');
      }
      if (stackTrace != null && level == LogLevel.error) {
        // ignore: avoid_print
        print('  StackTrace: $stackTrace');
      }
    }

    // Sentry breadcrumb (for context when errors occur)
    if (!kDebugMode) {
      Sentry.addBreadcrumb(Breadcrumb(
        message: formattedMessage,
        category: tag ?? 'app',
        level: _toSentryLevel(level),
        timestamp: DateTime.now(),
        data: error != null ? {'error': error.toString()} : null,
      ));
    }

    // Report errors to Sentry
    if (level == LogLevel.error && error != null && !kDebugMode) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'message': formattedMessage}),
      );
    }
  }

  static String _levelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  static String _colorize(LogLevel level, String message) {
    // ANSI color codes (work in most terminals)
    const reset = '\x1B[0m';
    const grey = '\x1B[90m';
    const green = '\x1B[32m';
    const yellow = '\x1B[33m';
    const red = '\x1B[31m';

    switch (level) {
      case LogLevel.debug:
        return '$grey$message$reset';
      case LogLevel.info:
        return '$green$message$reset';
      case LogLevel.warning:
        return '$yellow$message$reset';
      case LogLevel.error:
        return '$red$message$reset';
    }
  }

  static SentryLevel _toSentryLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return SentryLevel.debug;
      case LogLevel.info:
        return SentryLevel.info;
      case LogLevel.warning:
        return SentryLevel.warning;
      case LogLevel.error:
        return SentryLevel.error;
    }
  }
}

