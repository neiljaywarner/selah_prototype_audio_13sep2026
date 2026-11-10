import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feedback_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/remote_config/remote_config_service.dart';

import '../support/fakes/recording_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Remote config', () {
    test('knob options accept infinite, and a bad cache falls back to defaults', () async {
      const config = SelahRemoteConfig(knobOptions: '1, infinite, ∞, nope');
      expect(config.parsedKnobOptions, [1, -1, -1, 1]);
      expect(config.copyWith(silenceGapSeconds: 8).silenceGapSeconds, 8);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selah_remote_config_cache', '{not json');
      final service = RemoteConfigService(prefs: prefs);
      await service.init();

      expect(service.currentConfig.defaultTranslation, 'BSB');
      expect(service.currentConfig.featureVotingEnabled, isFalse);
      expect(service.getString('default_translation'), 'BSB');
      expect(service.getInt('silence_gap_seconds'), 4);
      expect(service.getBool('feature_voting_enabled'), isFalse);
    });

    test('a Firestore document updates the gap and the banner, and a failure keeps defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final adapter = RecordingHttpAdapter(
        statusCode: 200,
        body: jsonEncode({
          'fields': {
            'silence_gap_seconds': {'integerValue': '9'},
            'announcement_banner_text': {'stringValue': 'A quiet hour'},
            'enable_topic_tabs': {'booleanValue': true},
            'enable_emoji_feedback': {'booleanValue': false},
            'default_translation': {'stringValue': 'WEB'},
            'feedback_email_recipient': {'stringValue': 'care@example.com'},
            'github_feedback_token': {'stringValue': 'gho_test'},
          },
        }),
      );
      final service = RemoteConfigService(
        dio: Dio()..httpClientAdapter = adapter,
        prefs: prefs,
      );

      final refreshed = await service.fetchAndActivate();
      expect(refreshed.silenceGapSeconds, 9);
      expect(refreshed.announcementBannerText, 'A quiet hour');
      expect(refreshed.enableTopicTabs, isTrue);
      expect(refreshed.enableEmojiFeedback, isFalse);
      expect(refreshed.defaultTranslation, 'WEB');
      expect(prefs.getString('selah_remote_config_cache'), contains('A quiet hour'));

      adapter.error = DioException(
        requestOptions: RequestOptions(path: '/remote'),
        type: DioExceptionType.connectionError,
      );
      final kept = await service.fetchAndActivate();
      expect(kept.silenceGapSeconds, 9);
    });
  });

  group('Feedback when no tokens are configured', () {
    test('GitHub, Doorbell, and screenshot uploads do not pretend to succeed', () async {
      final adapter = RecordingHttpAdapter(statusCode: 500, body: '{}');
      final dio = Dio()..httpClientAdapter = adapter;

      expect(
        await FeedbackService.submitGitHubIssueFeedback(
          title: 'clip',
          body: 'verse started late',
          token: '',
          dioClient: dio,
        ),
        isFalse,
      );
      expect(adapter.requests, isEmpty);

      expect(
        await FeedbackService.submitDoorbellFeedback(
          message: 'the pause felt long',
          dioClient: dio,
        ),
        isTrue,
      );

      expect(
        await FeedbackService.uploadScreenshotAsset(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'shot.png',
          token: '',
          dioClient: dio,
        ),
        isNull,
      );
    });

    test('Firestore feedback is skipped in the test runner and still returns success', () async {
      final ok = await FeedbackService.submitFirestoreFeedback(
        rating: 5,
        emoji: '🕊️',
        face: 'happy',
        message: 'Peaceful',
      );
      expect(ok, isTrue);
    });
  });

  group('Feature voting notifier', () {
    test('a vote sticks, a blank remote cache is ignored, and curator review updates status', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selah_cached_feature_votes', 'not-json');
      final adapter = RecordingHttpAdapter(statusCode: 200, body: '{"documents":[]}');
      final service = FeatureVotingService(
        dio: Dio()..httpClientAdapter = adapter,
        prefs: prefs,
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          featureVotingServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(featureVotingProvider.notifier);
      await notifier.loadFeatures();
      final before = container.read(featureVotingProvider).features;
      expect(before.any((item) => item.id == 'karaoke_timestamps'), isTrue);
      expect(container.read(featureVotingProvider).isLoading, isFalse);

      await notifier.toggleVote('karaoke_timestamps');
      final voted = container
          .read(featureVotingProvider)
          .features
          .firstWhere((item) => item.id == 'karaoke_timestamps');
      expect(voted.hasVoted, isTrue);
      expect(voted.votes, 1);
      expect(adapter.requests, isNotEmpty);

      await notifier.toggleVote('missing');
      expect(
        container.read(featureVotingProvider).features.where((item) => item.hasVoted),
        hasLength(1),
      );

      await notifier.proposeFeature(title: 'Evening psalms', description: 'A night set');
      expect(container.read(featureVotingProvider).statusMessage, contains('curator review'));

      final proposed = container.read(featureVotingProvider).features.first;
      await notifier.approveFeature(proposed.id);
      expect(
        container.read(featureVotingProvider).features.first.status,
        'approved',
      );
      await notifier.rejectFeature(proposed.id);
      expect(
        container.read(featureVotingProvider).features.first.status,
        'declined',
      );

      await notifier.toggleCuratorMode();
      expect(container.read(featureVotingProvider).isCuratorMode, isTrue);
    });
  });
}
