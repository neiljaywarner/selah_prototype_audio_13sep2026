import 'package:selah_prototype_audio_13sep2026/src/core/analytics/analytics_service.dart';

/// In-memory [AnalyticsService]. Records events and errors and never calls
/// the network.
class FakeAnalytics implements AnalyticsService {
  FakeAnalytics({this.onEvent});

  final void Function(String eventName, Map<String, dynamic>? properties)? onEvent;

  final events = <String>[];
  final eventProperties = <Map<String, dynamic>?>[];
  final errors = <String>[];
  final errorPayloads = <Map<String, dynamic>>[];
  int initCount = 0;

  @override
  Future<void> init() async {
    initCount++;
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    events.add(eventName);
    eventProperties.add(properties);
    onEvent?.call(eventName, properties);
  }

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {
    errors.add(errorName);
    events.add('error:$errorName');
    errorPayloads.add({
      'error_name': errorName,
      'error': error?.toString(),
      ...?extraProperties,
    });
  }
}
