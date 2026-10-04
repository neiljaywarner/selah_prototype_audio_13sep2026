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
    if (!_initialized) return;
    debugPrint('🦔 [POSTHOG ERROR]: $errorName | $error');
  }
}
