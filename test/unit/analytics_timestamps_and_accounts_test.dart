import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/analytics_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/analytics_wrapper.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/firebase_analytics_provider.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/posthog_provider.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/web_gtag_helper.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/services/auth_repository.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/services/user_data_repository.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/telemetry/device_info_service.dart';

import '../support/fakes/fake_analytics.dart';
import '../support/fakes/recording_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics providers stay quiet without keys', () {
    test('Aptabase ignores the placeholder key', () async {
      final provider = AptabaseAnalyticsProvider(appKey: 'REDACTED');
      await provider.init();
      await provider.logEvent('play_chapter', {'book': 'JHN'});
      await provider.logError('boom', error: StateError('x'));
    });

    test('a bad Aptabase key is caught instead of crashing the player', () async {
      final provider = AptabaseAnalyticsProvider(appKey: 'not-a-real-key');
      await provider.init();
      await provider.logEvent('play_chapter');
      await provider.logError('boom');
    });

    test('PostHog does not capture when the key is missing, and does capture with a fake', () async {
      final silent = PostHogAnalyticsProvider(apiKey: '');
      await silent.init();
      await silent.logEvent('play_chapter');
      expect(silent.isInitialized, isFalse);

      final adapter = RecordingHttpAdapter(statusCode: 200, body: '{}');
      final live = PostHogAnalyticsProvider(
        apiKey: 'ph_test',
        host: 'https://us.i.posthog.com/',
        dioClient: Dio()..httpClientAdapter = adapter,
      );
      await live.init();
      expect(live.isInitialized, isTrue);
      expect(live.distinctId, startsWith('selah_'));
      await live.logEvent('play_chapter', {'book': 'PSA'});
      await live.logError('timing', error: Exception('late'), extraProperties: {'is_fatal': false});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(adapter.requests, isNotEmpty);
      final body = adapter.requestBodies.first as Map<String, dynamic>;
      expect(body['event'], 'play_chapter');
    });

    test('Firebase records an install id and a non-fatal error locally', () async {
      setMaestroDriving(true);
      addTearDown(() => setMaestroDriving(false));
      final firebase = FirebaseAnalyticsProvider();
      await firebase.init();
      expect(firebase.installationId, startsWith('inst_'));
      expect(firebase.userProperties['is_maestro'], 'true');
      await firebase.logEvent('open_player', {'passage': 'Psalm 23'});
      await firebase.logError('clip', extraProperties: {'is_fatal': false});
    });

    test('the wrapper still fans one event out to every provider', () async {
      final first = FakeAnalytics();
      final second = FakeAnalytics();
      final wrapper = AnalyticsWrapper([first, second]);
      await wrapper.init();
      await wrapper.logEvent('select_passage', {'reference': 'Psalm 23'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(first.events, contains('select_passage'));
      expect(second.events, contains('select_passage'));
      expect(first.initCount, 1);
    });
  });

  group('Device context in the test runner', () {
    test('reports the test device and does not look up a public IP', () async {
      setPatrolDriving(true);
      addTearDown(() => setPatrolDriving(false));
      final context = await AppDeviceInfoService.getClientContext();
      expect(context['device_model'], 'TestDevice');
      expect(context['public_ip'], '127.0.0.1');
      expect(context['app_version'], '0.4.1');
      expect(context['is_patrol'], isTrue);
      expect(context['platform'], defaultTargetPlatform.name);
    });
  });

  group('Timestamps', () {
    test('a missing asset is a quiet miss, and range coverage is exact', () async {
      expect(
        TimestampLoaderService.hasTimestampsFor(bookCode: 'REV', chapterNumber: 21),
        isFalse,
      );
      expect(
        TimestampLoaderService.hasCoverageForRange(
          bookCode: 'PSA',
          chapterNumber: 62,
          startVerse: 1,
          endVerse: 2,
        ),
        isTrue,
      );
      expect(
        TimestampLoaderService.hasCoverageForRange(
          bookCode: 'PSA',
          chapterNumber: 62,
          startVerse: 1,
          endVerse: 8,
        ),
        isFalse,
      );
      expect(
        TimestampLoaderService.hasCoverageForRange(
          bookCode: '1CO',
          chapterNumber: 13,
          startVerse: 4,
          endVerse: 7,
        ),
        isTrue,
      );

      final missing = await TimestampLoaderService.loadChapterTimestamps(
        translation: 'BSB',
        bookCode: 'REV',
        chapterNumber: 21,
      );
      expect(missing, isNull);

      final loaded = await TimestampLoaderService.loadChapterTimestamps(
        translation: 'BSB',
        bookCode: '1CO',
        chapterNumber: 13,
      );
      expect(loaded, isNotNull);
      expect(loaded!.first.text, contains('Love is patient'));

      final loose = VerseTimestamp.fromJson(const {});
      expect(loose.verse, 0);
      expect(loose.text, isEmpty);

      expect(
        TimestampLoaderService.estimateVerseTimestamps(
          textContent: '   ',
          totalDuration: const Duration(seconds: 30),
        ),
        isEmpty,
      );
      final estimated = TimestampLoaderService.estimateVerseTimestamps(
        textContent: '4 Love is patient, love is kind.\n5 It does not envy.',
        totalDuration: const Duration(seconds: 20),
      );
      expect(estimated, hasLength(2));
      expect(estimated.first.verse, 4);
      expect(estimated.first.text, contains('Love is patient'));
      expect(estimated.last.endMs, 20000);
      expect(estimated.first.startMs, lessThan(estimated.last.startMs));
    });
  });

  group('Local account stand-ins', () {
    test('anonymous sign-in, email sign-in, and sign-out', () async {
      final auth = InMemoryAuthRepository();
      expect(auth.currentUser?.isAnonymous, isTrue);
      final signedIn = await auth.signInWithEmailPassword('listener@example.com', 'unused');
      expect(signedIn.email, 'listener@example.com');
      expect(auth.authStateChanges, emits(signedIn));
      await auth.signOut();
      expect(auth.currentUser, isNull);
      final anon = await auth.signInAnonymously();
      expect(anon.isAnonymous, isTrue);
    });

    test('a favorite toggles off and a session can be saved', () async {
      final data = InMemoryScriptureUserDataRepository();
      expect(await data.getFavoritePassages('u1'), contains('PSA.23'));
      await data.toggleFavoritePassage('u1', 'PSA.23');
      expect(await data.getFavoritePassages('u1'), isNot(contains('PSA.23')));
      await data.toggleFavoritePassage('u1', 'JHN.1');
      expect(await data.getFavoritePassages('u1'), contains('JHN.1'));
      await data.saveMeditationSession(
        userId: 'u1',
        reference: 'Psalm 23',
        completedLoops: 3,
        durationSeconds: 120,
      );
    });
  });
}
