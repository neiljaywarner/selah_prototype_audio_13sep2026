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
    final stackTop = _extractTopFrames(stackTrace);
    final rawMessage = error?.toString() ?? errorName;
    final truncatedMessage = rawMessage.length > 220 ? '${rawMessage.substring(0, 220)}...' : rawMessage;

    final props = <String, dynamic>{
      'error_name': errorName,
      'error_type': extraProperties?['error_type']?.toString() ?? error?.runtimeType.toString() ?? 'UnknownError',
      'error_message': truncatedMessage,
      'http_status': extraProperties?['http_status'] ?? 0,
      'endpoint': extraProperties?['endpoint']?.toString() ?? '',
      'book_code': extraProperties?['book_code']?.toString() ?? '',
      'chapter': extraProperties?['chapter'] ?? 0,
      'translation': extraProperties?['translation']?.toString() ?? '',
      'audio_mode': extraProperties?['audio_mode']?.toString() ?? '',
      'stack_top': stackTop,
      'platform': defaultTargetPlatform.name,
      'is_fatal': extraProperties?['is_fatal'] == true,
      ...?extraProperties,
    };

    if (appKey == 'REDACTED' || appKey.isEmpty) {
      debugPrint('📊 [APTABASE ERROR (DEV)]: app_error => $props');
      return;
    }

    try {
      await Aptabase.instance.trackEvent('app_error', props);
      debugPrint('📊 [APTABASE ERROR SENT]: app_error => $props');
    } catch (e) {
      debugPrint('🔴 [ANALYTICS ERROR LOG FAILED]: $e');
    }
  }

  static String _extractTopFrames(StackTrace? stackTrace) {
    if (stackTrace == null) return '';
    final lines = stackTrace
        .toString()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .take(3)
        .join(' | ');
    return lines.length > 240 ? '${lines.substring(0, 240)}...' : lines;
  }
}
