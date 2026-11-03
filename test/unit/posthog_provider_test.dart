import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/posthog_provider.dart';

void main() {
  group('PostHogAnalyticsProvider Tests', () {
    test('init() with REDACTED key disables tracking safely', () async {
      final provider = PostHogAnalyticsProvider(apiKey: 'REDACTED');
      await provider.init();

      expect(provider.isInitialized, isFalse);
      expect(provider.distinctId, equals('unknown'));
    });

    test('init() with valid key generates unique distinct ID and initializes', () async {
      final provider = PostHogAnalyticsProvider(
        apiKey: 'test_posthog_key_12345',
        host: 'https://us.i.posthog.com',
      );
      await provider.init();

      expect(provider.isInitialized, isTrue);
      expect(provider.distinctId, startsWith('selah_'));
    });

    test('logEvent() with active key dispatches capture POST payload', () async {
      RequestOptions? capturedOptions;
      dynamic capturedData;

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            capturedData = options.data;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'status': 1},
              ),
            );
          },
        ),
      );

      final provider = PostHogAnalyticsProvider(
        apiKey: 'test_posthog_key_12345',
        host: 'https://us.i.posthog.com',
        dioClient: dio,
      );
      await provider.init();

      await provider.logEvent('select_knob_value', {
        'knob': 'repetitions',
        'selected_value': 7,
      });

      // Allow microtask / unawaited post to resolve
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, equals('/capture/'));
      expect(capturedData, isA<Map<String, dynamic>>());
      final dataMap = capturedData as Map<String, dynamic>;
      expect(dataMap['api_key'], equals('test_posthog_key_12345'));
      expect(dataMap['event'], equals('select_knob_value'));
      expect(dataMap['properties']['knob'], equals('repetitions'));
      expect(dataMap['properties']['selected_value'], equals(7));
    });

    test('logError() formats and forwards exception event to PostHog', () async {
      dynamic capturedData;

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedData = options.data;
            return handler.resolve(
              Response(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );

      final provider = PostHogAnalyticsProvider(
        apiKey: 'test_posthog_key_12345',
        dioClient: dio,
      );
      await provider.init();

      await provider.logError(
        'audio_decode_failure',
        error: FormatException('Invalid audio header'),
        extraProperties: {'book_code': 'PSA', 'chapter': 23},
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(capturedData, isNotNull);
      final dataMap = capturedData as Map<String, dynamic>;
      expect(dataMap['event'], equals(r'$exception'));
      expect(dataMap['properties']['error_name'], equals('audio_decode_failure'));
      expect(dataMap['properties']['book_code'], equals('PSA'));
    });
  });
}
