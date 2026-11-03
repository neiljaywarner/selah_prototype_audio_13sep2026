import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

class PostHogAnalyticsProvider implements AnalyticsService {
  final String apiKey;
  final String host;
  final Dio _dio;
  bool _initialized = false;
  String _distinctId = 'unknown';

  PostHogAnalyticsProvider({
    this.apiKey = 'REDACTED',
    this.host = 'https://us.i.posthog.com',
    Dio? dioClient,
  }) : _dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: host.endsWith('/') ? host.substring(0, host.length - 1) : host,
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 5),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  bool get isInitialized => _initialized;
  String get distinctId => _distinctId;

  @override
  Future<void> init() async {
    if (apiKey == 'REDACTED' || apiKey.isEmpty) {
      debugPrint('🦔 [POSTHOG]: Key is REDACTED. PostHog tracking disabled for dev.');
      return;
    }
    _distinctId = 'selah_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    _initialized = true;
    debugPrint('🦔 [POSTHOG]: Initialized for host $host (distinctId: $_distinctId)');
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (!_initialized || apiKey == 'REDACTED' || apiKey.isEmpty) return;

    final payload = {
      'api_key': apiKey,
      'event': eventName,
      'properties': {
        'distinct_id': _distinctId,
        r'$lib': 'selah_flutter',
        r'$lib_version': '0.4.1',
        'k_debug_mode': kDebugMode,
        'platform': defaultTargetPlatform.name,
        'is_web': kIsWeb,
        ...?properties,
      },
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      unawaited(
        _dio.post('/capture/', data: payload).then((response) {
          debugPrint('🦔 [POSTHOG SENT]: $eventName (${response.statusCode})');
        }).catchError((e) {
          debugPrint('🔴 [POSTHOG POST ERROR]: $e');
        }),
      );
    } catch (e) {
      debugPrint('🔴 [POSTHOG DISPATCH FAILED]: $e');
    }
  }

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {
    final exceptionProps = <String, dynamic>{
      r'$exception_type': extraProperties?['error_type'] ?? error?.runtimeType.toString() ?? 'Error',
      r'$exception_message': error?.toString() ?? errorName,
      r'$exception_personURL': host,
      'error_name': errorName,
      if (stackTrace != null)
        r'$exception_stack_trace_raw': stackTrace.toString().split('\n').take(5).join('\n'),
      ...?extraProperties,
    };

    if (!_initialized) {
      debugPrint('🦔 [POSTHOG ERROR (DEV)]: \$exception => $exceptionProps');
      return;
    }

    await logEvent(r'$exception', exceptionProps);
  }
}
