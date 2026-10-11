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

  final List<Map<String, dynamic>> loggedErrorPayloads = [];

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {
    loggedEvents.add('error:$errorName');
    loggedErrorPayloads.add({
      'error_name': errorName,
      'error': error?.toString(),
      ...?extraProperties,
    });
  }
}

void main() {
  group('AnalyticsWrapper & Error Reporting Tests', () {
    test('Broadcasts events to all registered providers with unawaited dispatch', () async {
      final mock1 = MockAnalyticsProvider();
      final mock2 = MockAnalyticsProvider();

      final wrapper = AnalyticsWrapper([mock1, mock2]);
      await wrapper.init();

      await wrapper.logEvent('play_chapter', {'book': 'JHN', 'chapter': 1});

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mock1.loggedEvents, contains('play_chapter'));
      expect(mock2.loggedEvents, contains('play_chapter'));
    });

    test('Broadcasts structured error events with chapter and translation params to all providers', () async {
      final aptabaseMock = MockAnalyticsProvider();
      final firebaseMock = MockAnalyticsProvider();
      final posthogMock = MockAnalyticsProvider();

      final wrapper = AnalyticsWrapper([aptabaseMock, firebaseMock, posthogMock]);
      await wrapper.init();

      await wrapper.logError(
        'API.Bible narrator fetch failed for JHN.1',
        error: Exception('Network timeout'),
        stackTrace: StackTrace.current,
        extraProperties: {
          'book_code': 'JHN',
          'chapter': 1,
          'translation': 'BSB',
          'audio_mode': 'narrator',
          'http_status': 503,
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      for (final provider in [aptabaseMock, firebaseMock, posthogMock]) {
        expect(provider.loggedEvents, contains('error:API.Bible narrator fetch failed for JHN.1'));
        expect(provider.loggedErrorPayloads.first['book_code'], 'JHN');
        expect(provider.loggedErrorPayloads.first['chapter'], 1);
        expect(provider.loggedErrorPayloads.first['translation'], 'BSB');
        expect(provider.loggedErrorPayloads.first['http_status'], 503);
      }
    });
  });
}
