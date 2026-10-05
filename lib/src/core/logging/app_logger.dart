import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';
import '../constants/api_constants.dart';

class AppLogger {
  static AnalyticsService? _analytics;
  static final List<String> _inMemoryLogs = [];

  static void init(AnalyticsService analytics) {
    _analytics = analytics;
    info('AppLogger initialized');
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
    _inMemoryLogs.insert(0, logLine);
    if (_inMemoryLogs.length > 60) _inMemoryLogs.removeLast();
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

    _inMemoryLogs.insert(0, logLine);
    if (_inMemoryLogs.length > 60) _inMemoryLogs.removeLast();

    final errorProps = <String, dynamic>{'message': message, ...?properties};

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
