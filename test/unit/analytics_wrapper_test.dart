import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/analytics_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/analytics_wrapper.dart';

class MockAnalyticsProvider implements AnalyticsService {
  final List<String> loggedEvents = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    loggedEvents.add(eventName);
  }

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {
    loggedEvents.add('error:$errorName');
  }
}

void main() {
  group('AnalyticsWrapper Tests', () {
    test('Broadcasts events to all registered providers with unawaited dispatch', () async {
      final mock1 = MockAnalyticsProvider();
      final mock2 = MockAnalyticsProvider();

      final wrapper = AnalyticsWrapper([mock1, mock2]);
      await wrapper.init();

      await wrapper.logEvent('play_chapter', {'book': 'COL', 'chapter': 1});

      // Small async tick for unawaited tasks
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mock1.loggedEvents, contains('play_chapter'));
      expect(mock2.loggedEvents, contains('play_chapter'));
    });
  });
}
