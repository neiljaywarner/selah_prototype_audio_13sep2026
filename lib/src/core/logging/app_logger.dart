import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../analytics/analytics_service.dart';
import '../constants/api_constants.dart';

class AppLogger {
  static AnalyticsService? _analytics;
  static final Talker talker = TalkerFlutter.init(
    settings: TalkerSettings(
      useHistory: true,
      maxHistoryItems: 200,
    ),
  );
  static final List<String> _inMemoryLogs = [];

  static void init(AnalyticsService analytics) {
    _analytics = analytics;
    registerGlobalErrorHandlers();
    info('AppLogger initialized with global error wrapper & Talker (Aptabase + Firebase Crashlytics + PostHog)');
  }

  static void registerGlobalErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      error(
        'FlutterFrameworkError: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
        properties: {
          'library': details.library ?? 'flutter',
          'context': details.context?.toDescription() ?? '',
          'is_fatal': false,
        },
      );
    };

    PlatformDispatcher.instance.onError = (Object err, StackTrace stack) {
      error(
        'UncaughtPlatformError',
        error: err,
        stackTrace: stack,
        properties: {'is_fatal': true},
      );
      return true;
    };
  }

  static String exportDiagnosticReport({
    required String activeTranslation,
    required String currentChapter,
    required String audioMode,
  }) {
    final buffer = StringBuffer()
      ..writeln('=== SELAH v0.2_mini DIAGNOSTIC REPORT ===')
      ..writeln('Timestamp: ${DateTime.now().toIso8601String()}')
      ..writeln('Platform: ${defaultTargetPlatform.name} (kIsWeb: $kIsWeb)')
      ..writeln('Active Translation: $activeTranslation')
      ..writeln('Current Chapter: $currentChapter')
      ..writeln('Audio Mode: $audioMode')
      ..writeln('API.Bible Key Configured: ${kApiBibleKey != "REDACTED" && kApiBibleKey.isNotEmpty}')
      ..writeln('Aptabase Key Configured: ${kAptabaseAppKey != "REDACTED" && kAptabaseAppKey.isNotEmpty}')
      ..writeln('--- RECENT LOGS (${_inMemoryLogs.length}) ---');
    for (final line in _inMemoryLogs) {
      buffer.writeln(line);
    }
    return _sanitize(buffer.toString());
  }

  static List<String> get logs => List.unmodifiable(_inMemoryLogs);

  static String _sanitize(String text) {
    var sanitized = text;
    if (kApiBibleKey != 'REDACTED' && kApiBibleKey.isNotEmpty) {
      sanitized = sanitized.replaceAll(kApiBibleKey, '[REDACTED_API_KEY]');
    }
    if (kAptabaseAppKey != 'REDACTED' && kAptabaseAppKey.isNotEmpty) {
      sanitized = sanitized.replaceAll(kAptabaseAppKey, '[REDACTED_APTABASE_KEY]');
    }
    return sanitized;
  }

  static void info(String message, [Map<String, dynamic>? properties]) {
    final timeStr = DateTime.now().toIso8601String();
    final timeFormatted = timeStr.length >= 19 ? timeStr.substring(11, 19) : timeStr;
    final rawLine = 'ℹ️ [SELAH INFO] $timeFormatted: $message ${properties ?? ""}';
    final logLine = _sanitize(rawLine);
    debugPrint(logLine);
    talker.info('$message ${properties ?? ""}');
    _inMemoryLogs.insert(0, logLine);
    if (_inMemoryLogs.length > 80) _inMemoryLogs.removeLast();
  }

  static void warning(String message, [Map<String, dynamic>? properties]) {
    final timeStr = DateTime.now().toIso8601String();
    final timeFormatted = timeStr.length >= 19 ? timeStr.substring(11, 19) : timeStr;
    final rawLine = '⚠️ [SELAH WARN] $timeFormatted: $message ${properties ?? ""}';
    final logLine = _sanitize(rawLine);
    debugPrint(logLine);
    talker.warning('$message ${properties ?? ""}');
    _inMemoryLogs.insert(0, logLine);
    if (_inMemoryLogs.length > 80) _inMemoryLogs.removeLast();
  }

  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? properties,
  }) {
    final timeStr = DateTime.now().toIso8601String();
    final timeFormatted = timeStr.length >= 19 ? timeStr.substring(11, 19) : timeStr;
    final rawLine = '🔴 [SELAH ERROR] $timeFormatted: $message | Details: $error';
    final logLine = _sanitize(rawLine);
    debugPrint(logLine);
    if (stackTrace != null) debugPrint(_sanitize(stackTrace.toString()));

    talker.handle(error ?? message, stackTrace, message);

    _inMemoryLogs.insert(0, logLine);
    if (_inMemoryLogs.length > 80) _inMemoryLogs.removeLast();

    final errorProps = <String, dynamic>{'message': _sanitize(message), ...?properties};

    if (error is DioException) {
      errorProps['http_status'] = error.response?.statusCode ?? 0;
      errorProps['endpoint'] = _sanitize(error.requestOptions.uri.toString());
      errorProps['error_type'] = 'DioException';
    } else if (error != null) {
      errorProps['error_type'] = error.runtimeType.toString();
    }

    _analytics?.logError(
      _sanitize(message),
      error: error,
      stackTrace: stackTrace,
      extraProperties: errorProps,
    );
  }

  static void logEvent(String eventName, [Map<String, dynamic>? properties]) {
    info('EVENT: $eventName', properties);
    _analytics?.logEvent(eventName, properties);
  }
}
