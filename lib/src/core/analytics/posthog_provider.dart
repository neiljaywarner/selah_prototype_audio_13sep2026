import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

class PostHogAnalyticsProvider implements AnalyticsService {
  final String apiKey;
  final String host;
  bool _initialized = false;

  PostHogAnalyticsProvider({
    this.apiKey = 'REDACTED',
    this.host = 'https://app.posthog.com',
  });

  @override
  Future<void> init() async {
    if (apiKey == 'REDACTED' || apiKey.isEmpty) {
      debugPrint('🦔 [POSTHOG]: Key is REDACTED. PostHog tracking disabled for dev.');
      return;
    }
    _initialized = true;
    debugPrint('🦔 [POSTHOG]: Initialized for host $host');
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (!_initialized) return;
    debugPrint('🦔 [POSTHOG EVENT]: $eventName => ${properties ?? {}}');
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
    debugPrint('🦔 [POSTHOG ERROR SENT]: \$exception => $exceptionProps');
  }
}
