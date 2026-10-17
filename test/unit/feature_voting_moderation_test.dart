import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feature_voting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Voting Curator Moderation Gate (v0.3.8)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('All default roadmap features are pre-approved with approved status', () {
      for (final feature in FeatureVotingService.defaultFeatures) {
        expect(feature.isApproved, isTrue, reason: '${feature.id} should be pre-approved');
        expect(feature.status, equals('approved'));
      }
    });

    test('User proposing a feature starts in quarantined pending_approval state', () async {
      final service = FeatureVotingService();
      final item = await service.proposeFeature(
        title: 'Custom Sleep Soundscapes',
        description: 'Nature sounds tailored to meditation.',
      );

      expect(item.isApproved, isFalse, reason: 'New community proposals must be quarantined');
      expect(item.status, equals('pending_approval'));
      expect(item.votes, equals(1));
      expect(item.hasVoted, isTrue);

      final localProposals = await service.getLocalProposals();
      expect(localProposals.any((p) => p.id == item.id), isTrue);
    });

    test('fetchFeatures hides unapproved proposals for standard users', () async {
      final service = FeatureVotingService();
      await service.proposeFeature(
        title: 'Gentle Bell Chimes',
        description: 'Tibetan bell chimes between loops.',
      );

      final publicFeatures = await service.fetchFeatures(includePending: false);
      expect(
        publicFeatures.any((f) => f.title == 'Gentle Bell Chimes'),
        isFalse,
        reason: 'Public feed must only show approved features',
      );
      for (final f in publicFeatures) {
        expect(f.isApproved, isTrue);
      }
    });

    test('fetchFeatures includes unapproved proposals when includePending is true (Curator Mode)', () async {
      final service = FeatureVotingService();
      await service.proposeFeature(
        title: 'Breathe Bar Pulse',
        description: 'Paced breath indicator.',
      );

      final curatorFeatures = await service.fetchFeatures(includePending: true);
      expect(
        curatorFeatures.any((f) => f.title == 'Breathe Bar Pulse'),
        isTrue,
        reason: 'Curator mode must reveal pending proposals for moderation',
      );
    });

    test('Curator can approve a pending proposal to make it public', () async {
      final service = FeatureVotingService();
      final item = await service.proposeFeature(
        title: 'Multi-lingual Narration',
        description: 'Spanish, Portuguese, and Mandarin audio.',
      );

      // Verify unapproved initially
      var publicFeatures = await service.fetchFeatures(includePending: false);
      expect(publicFeatures.any((f) => f.id == item.id), isFalse);

      // Approve
      await service.approveFeature(item);

      // Verify visible in public feed
      publicFeatures = await service.fetchFeatures(includePending: false);
      final approvedItem = publicFeatures.firstWhere((f) => f.id == item.id);
      expect(approvedItem.isApproved, isTrue);
      expect(approvedItem.status, equals('approved'));
    });

    test('Curator can reject a proposal marking it declined', () async {
      final service = FeatureVotingService();
      final item = await service.proposeFeature(
        title: 'Unvetted Proposal',
        description: 'Test spam or irrelevant suggestion.',
      );

      await service.rejectFeature(item);

      final curatorFeatures = await service.fetchFeatures(includePending: true);
      final rejected = curatorFeatures.firstWhere((f) => f.id == item.id);
      expect(rejected.isApproved, isFalse);
      expect(rejected.status, equals('declined'));

      final publicFeatures = await service.fetchFeatures(includePending: false);
      expect(publicFeatures.any((f) => f.id == item.id), isFalse);
    });

    test('Curator mode flag persists in SharedPreferences', () async {
      final service = FeatureVotingService();
      expect(await service.isCuratorModeEnabled(), isFalse);

      await service.setCuratorMode(true);
      expect(await service.isCuratorModeEnabled(), isTrue);

      await service.setCuratorMode(false);
      expect(await service.isCuratorModeEnabled(), isFalse);
    });

    test('RoadmapFeatureItem serialization correctly handles approval state', () {
      const item = RoadmapFeatureItem(
        id: 'test_item',
        title: 'Test Feature',
        description: 'Testing description',
        targetVersion: 'v0.4',
        votes: 12,
        isApproved: false,
        status: 'pending_approval',
      );

      final json = item.toJson();
      expect(json['isApproved'], isFalse);
      expect(json['status'], equals('pending_approval'));

      final fromJson = RoadmapFeatureItem.fromJson(json);
      expect(fromJson.isApproved, isFalse);
      expect(fromJson.status, equals('pending_approval'));

      final fromFirestore = RoadmapFeatureItem.fromFirestoreJson(
        'test_item',
        {
          'title': {'stringValue': 'Test Feature'},
          'description': {'stringValue': 'Testing description'},
          'targetVersion': {'stringValue': 'v0.4'},
          'votes': {'integerValue': '12'},
          'approved': {'booleanValue': true},
          'status': {'stringValue': 'approved'},
        },
      );
      expect(fromFirestore.isApproved, isTrue);
      expect(fromFirestore.status, equals('approved'));
    });
  });
}
