import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../analytics/analytics_service.dart';

class AppLogger {
  static AnalyticsService? _analytics;
  static final List<String> _inMemoryLogs = [];

  static void init(AnalyticsService analytics) {
    _analytics = analytics;
    info('AppLogger initialized');
  }

  static List<String> get logs => List.unmodifiable(_inMemoryLogs);

  static void info(String message, [Map<String, dynamic>? properties]) {
    final timeStr = DateTime.now().toIso8601String();
    final timeFormatted = timeStr.length >= 19 ? timeStr.substring(11, 19) : timeStr;
    final logLine = 'ℹ️ [SELAH INFO] $timeFormatted: $message ${properties ?? ""}';
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
    final logLine = '🔴 [SELAH ERROR] $timeFormatted: $message | Details: $error';
    debugPrint(logLine);
    if (stackTrace != null) debugPrint(stackTrace.toString());

    _inMemoryLogs.insert(0, logLine);
    if (_inMemoryLogs.length > 60) _inMemoryLogs.removeLast();

    final errorProps = <String, dynamic>{'message': message, ...?properties};

    if (error is DioException) {
      errorProps['http_status'] = error.response?.statusCode ?? 0;
      errorProps['endpoint'] = error.requestOptions.uri.toString();
      errorProps['error_type'] = 'DioException';
    } else if (error != null) {
      errorProps['error_type'] = error.runtimeType.toString();
    }

    _analytics?.logError(
      message,
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
