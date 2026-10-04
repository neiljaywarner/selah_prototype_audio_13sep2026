import 'dart:async';
import 'analytics_service.dart';

class AnalyticsWrapper implements AnalyticsService {
  final List<AnalyticsService> _providers;

  AnalyticsWrapper(this._providers);

  @override
  Future<void> init() async {
    for (final provider in _providers) {
      try {
        await provider.init();
      } catch (_) {}
    }
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    for (final provider in _providers) {
      unawaited(
        provider.logEvent(eventName, properties).catchError((_) {}),
      );
    }
  }

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {
    for (final provider in _providers) {
      unawaited(
        provider
            .logError(
              errorName,
              error: error,
              stackTrace: stackTrace,
              extraProperties: extraProperties,
            )
            .catchError((_) {}),
      );
    }
  }
}
