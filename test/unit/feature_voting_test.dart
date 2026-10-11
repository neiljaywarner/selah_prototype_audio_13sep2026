import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeatureVotingService and Model Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaultFeatures contains realistic community vote baselines', () {
      final features = FeatureVotingService.defaultFeatures;
      expect(features, isNotEmpty);
      expect(features.any((f) => f.id == 'karaoke_timestamps'), isTrue);

      final karaoke = features.firstWhere((f) => f.id == 'karaoke_timestamps');
      expect(karaoke.votes, greaterThan(0));
      expect(karaoke.votes, equals(42));
      expect(karaoke.hasVoted, isFalse);
    });

    test('RoadmapFeatureItem serialization to and from JSON', () {
      const item = RoadmapFeatureItem(
        id: 'test_item',
        title: 'Test Feature',
        description: 'Test Description',
        targetVersion: 'v0.5',
        votes: 10,
        hasVoted: true,
      );

      final json = item.toJson();
      final restored = RoadmapFeatureItem.fromJson(json);

      expect(restored.id, equals('test_item'));
      expect(restored.title, equals('Test Feature'));
      expect(restored.description, equals('Test Description'));
      expect(restored.targetVersion, equals('v0.5'));
      expect(restored.votes, equals(10));
      expect(restored.hasVoted, isTrue);
    });

    test('RoadmapFeatureItem fromFirestoreJson parses Firestore REST structure', () {
      final fields = {
        'title': {'stringValue': 'Cloud Sync'},
        'description': {'stringValue': 'Sync prayers and audio bookmarks'},
        'targetVersion': {'stringValue': 'v0.4'},
        'votes': {'integerValue': '99'},
      };

      final item = RoadmapFeatureItem.fromFirestoreJson('cloud_sync', fields, hasVoted: false);

      expect(item.id, equals('cloud_sync'));
      expect(item.title, equals('Cloud Sync'));
      expect(item.description, equals('Sync prayers and audio bookmarks'));
      expect(item.targetVersion, equals('v0.4'));
      expect(item.votes, equals(99));
      expect(item.hasVoted, isFalse);
    });

    test('FeatureVotingService saves and loads voted feature IDs in SharedPreferences', () async {
      final service = FeatureVotingService();
      await service.saveVotedFeatureIds({'karaoke_timestamps', 'ambient_soundscapes'});

      final loaded = await service.getVotedFeatureIds();
      expect(loaded, contains('karaoke_timestamps'));
      expect(loaded, contains('ambient_soundscapes'));
      expect(loaded.contains('gemini_voice_memorization'), isFalse);
    });
  });

  group('FeatureVotingNotifier Riverpod Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Voting toggle increments vote count and toggling again decrements', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(featureVotingProvider.notifier);
      final initialFeatures = container.read(featureVotingProvider).features;
      final initialKaraoke = initialFeatures.firstWhere((f) => f.id == 'karaoke_timestamps');
      final baselineVotes = initialKaraoke.votes;

      // 1. Cast Vote
      await notifier.toggleVote('karaoke_timestamps');
      final stateAfterVote = container.read(featureVotingProvider);
      final votedItem = stateAfterVote.features.firstWhere((f) => f.id == 'karaoke_timestamps');

      expect(votedItem.hasVoted, isTrue);
      expect(votedItem.votes, equals(baselineVotes + 1));

      // 2. Un-vote
      await notifier.toggleVote('karaoke_timestamps');
      final stateAfterUnvote = container.read(featureVotingProvider);
      final unvotedItem = stateAfterUnvote.features.firstWhere((f) => f.id == 'karaoke_timestamps');

      expect(unvotedItem.hasVoted, isFalse);
      expect(unvotedItem.votes, equals(baselineVotes));
    });
  });

  group('FeedbackService Doorbell Unit Tests', () {
    test('submitDoorbellFeedback completes gracefully and caches locally when unconfigured', () async {
      final result = await FeedbackService.submitDoorbellFeedback(
        message: 'Loving the peaceful narration and loop modes!',
        email: 'user@example.com',
        sentiment: 'positive',
        nps: 10,
      );
      expect(result, isTrue);
    });
  });
}
