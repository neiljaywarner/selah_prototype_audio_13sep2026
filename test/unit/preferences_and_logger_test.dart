import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/logging/app_logger.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';

import '../support/fakes/fake_analytics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User preferences', () {
    test('a missing store keeps the contemplative defaults', () async {
      final prefs = UserPreferences(null);
      expect(prefs.lastTranslationCode, isNull);
      expect(prefs.savedChapters, isEmpty);
      expect(prefs.experimentalApiBibleNarrator, isFalse);
      expect(prefs.showWorkInProgressFeatures, isFalse);
      expect(prefs.catalogTier, CatalogTier.biblical40);

      await prefs.saveChapter('Psalm 23');
      await prefs.setLastTranslationCode('WEB');
      await prefs.setExperimentalApiBibleNarrator(true);
      expect(prefs.savedChapters, isEmpty);
      expect(prefs.lastTranslationCode, isNull);
    });

    test('catalog tier and work-in-progress flags round-trip, and junk falls back', () async {
      SharedPreferences.setMockInitialValues({
        UserPreferences.catalogTierKey: 'not-a-tier',
      });
      final stored = await SharedPreferences.getInstance();
      final prefs = UserPreferences(stored);
      expect(prefs.catalogTier, CatalogTier.biblical40);

      await prefs.setCatalogTier(CatalogTier.curated12);
      expect(prefs.catalogTier.label, 'Curated 12');
      expect(CatalogTier.softLaunch77.emoji, '🕊️');

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(stored)],
      );
      addTearDown(container.dispose);

      expect(container.read(catalogTierProvider), CatalogTier.curated12);
      await container.read(catalogTierProvider.notifier).setTier(CatalogTier.allPassages);
      expect(container.read(catalogTierProvider).label, 'All 66 Books');

      expect(container.read(workInProgressFeaturesProvider), isFalse);
      await container.read(workInProgressFeaturesProvider.notifier).setEnabled(true);
      expect(stored.getBool(UserPreferences.showWorkInProgressFeaturesKey), isTrue);

      await container.read(experimentalApiBibleNarratorProvider.notifier).setEnabled(true);
      expect(container.read(experimentalApiBibleNarratorProvider), isTrue);
    });
  });

  group('App logger', () {
    test('diagnostic report hides keys and keeps a bounded log', () {
      final analytics = FakeAnalytics();
      AppLogger.init(analytics);

      for (var i = 0; i < 85; i++) {
        AppLogger.info('line $i');
      }
      AppLogger.warning('headphones unplugged', {'reason': 'noisy'});

      expect(AppLogger.logs.length, 80);
      expect(AppLogger.logs.first, contains('headphones unplugged'));

      final report = AppLogger.exportDiagnosticReport(
        activeTranslation: 'BSB',
        currentChapter: '1 Cor 13:4–7',
        audioMode: 'narrator',
      );
      expect(report, contains('ESV Key Configured: false'));
      expect(report, contains('API.Bible Key Configured: false'));
      expect(report, isNot(contains('sk_live')));
    });

    test('a Dio failure is recorded with status and endpoint, and forwarded', () {
      final analytics = FakeAnalytics();
      AppLogger.init(analytics);
      final request = RequestOptions(path: '/audio-bibles/bsb/chapters/JHN.1');
      final dioError = DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 503),
        type: DioExceptionType.badResponse,
      );

      AppLogger.error(
        'narrator fetch failed',
        error: dioError,
        stackTrace: StackTrace.current,
        properties: {'book_code': 'JHN', 'chapter': 1},
      );

      expect(analytics.errors.single, 'narrator fetch failed');
      expect(analytics.errorPayloads.single['http_status'], 503);
      expect(analytics.errorPayloads.single['error_type'], 'DioException');
      expect(analytics.errorPayloads.single['book_code'], 'JHN');
      expect(AppLogger.logs.first, contains('narrator fetch failed'));
    });
  });
}
