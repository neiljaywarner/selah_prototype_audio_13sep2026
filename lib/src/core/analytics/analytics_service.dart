import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';

abstract class AnalyticsService {
  Future<void> init();
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]);
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  });
}

class AptabaseAnalyticsProvider implements AnalyticsService {
  final String appKey;
  AptabaseAnalyticsProvider({required this.appKey});

  @override
  Future<void> init() async {
    if (appKey == 'REDACTED' || appKey.isEmpty) {
      debugPrint(
        '⚠️ [APTABASE]: Key is REDACTED. Analytics tracking disabled for dev/public build.',
      );
      return;
    }
    try {
      await Aptabase.init(appKey);
      debugPrint(
        '⚡ [APTABASE]: Analytics initialized successfully with key prefix ${appKey.substring(0, appKey.length >= 7 ? 7 : appKey.length)}',
      );
    } catch (e) {
      debugPrint('🔴 [APTABASE INIT ERROR]: $e');
    }
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (appKey == 'REDACTED' || appKey.isEmpty) return;
    try {
      await Aptabase.instance.trackEvent(eventName, properties);
      debugPrint('📊 [ANALYTICS EVENT]: $eventName => ${properties ?? {}}');
    } catch (e) {
      debugPrint('🔴 [ANALYTICS TRACK ERROR]: $e');
    }
  }

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {
    if (appKey == 'REDACTED' || appKey.isEmpty) return;
    final props = <String, dynamic>{
      'error_name': errorName,
      'details': error?.toString(),
      ...?extraProperties,
    };
    try {
      await Aptabase.instance.trackEvent('app_error', props);
    } catch (e) {
      debugPrint('🔴 [ANALYTICS ERROR LOG FAILED]: $e');
    }
  }
}
