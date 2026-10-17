import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/app_logger.dart';
import 'feature_voting_service.dart';

class FeatureVotingState {
  final List<RoadmapFeatureItem> features;
  final bool isLoading;
  final bool isCuratorMode;
  final String? statusMessage;

  const FeatureVotingState({
    required this.features,
    this.isLoading = false,
    this.isCuratorMode = false,
    this.statusMessage,
  });

  FeatureVotingState copyWith({
    List<RoadmapFeatureItem>? features,
    bool? isLoading,
    bool? isCuratorMode,
    String? statusMessage,
    bool clearStatus = false,
  }) {
    return FeatureVotingState(
      features: features ?? this.features,
      isLoading: isLoading ?? this.isLoading,
      isCuratorMode: isCuratorMode ?? this.isCuratorMode,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

final featureVotingServiceProvider = Provider<FeatureVotingService>((ref) {
  return FeatureVotingService();
});

final featureVotingProvider =
    NotifierProvider<FeatureVotingNotifier, FeatureVotingState>(
  FeatureVotingNotifier.new,
);

class FeatureVotingNotifier extends Notifier<FeatureVotingState> {
  late final FeatureVotingService _service;

  @override
  FeatureVotingState build() {
    _service = ref.watch(featureVotingServiceProvider);
    return FeatureVotingState(
      features: FeatureVotingService.defaultFeatures,
      isLoading: false,
      isCuratorMode: false,
    );
  }

  Future<void> loadFeatures() async {
    state = state.copyWith(isLoading: true);
    try {
      final isCurator = await _service.isCuratorModeEnabled();
      final remoteFeatures = await _service.fetchFeatures(includePending: isCurator);
      final votedIds = await _service.getVotedFeatureIds();
      final merged = remoteFeatures.map((f) {
        final hasVoted = votedIds.contains(f.id);
        return f.copyWith(hasVoted: hasVoted);
      }).toList();
      state = state.copyWith(
        features: merged,
        isCuratorMode: isCurator,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.info('Feature voting loadNotice: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleCuratorMode() async {
    final nextMode = !state.isCuratorMode;
    await _service.setCuratorMode(nextMode);
    state = state.copyWith(isCuratorMode: nextMode);
    await loadFeatures();
  }

  Future<void> approveFeature(String featureId) async {
    final itemIndex = state.features.indexWhere((f) => f.id == featureId);
    if (itemIndex == -1) return;

    final targetItem = state.features[itemIndex];
    await _service.approveFeature(targetItem);

    final updatedItem = targetItem.copyWith(isApproved: true, status: 'approved');
    final updatedList = List<RoadmapFeatureItem>.from(state.features);
    updatedList[itemIndex] = updatedItem;

    state = state.copyWith(
      features: updatedList,
      statusMessage: '✨ Feature "${targetItem.title}" approved for the public roadmap. 🙏',
    );
  }

  Future<void> rejectFeature(String featureId) async {
    final itemIndex = state.features.indexWhere((f) => f.id == featureId);
    if (itemIndex == -1) return;

    final targetItem = state.features[itemIndex];
    await _service.rejectFeature(targetItem);

    final updatedItem = targetItem.copyWith(isApproved: false, status: 'declined');
    final updatedList = List<RoadmapFeatureItem>.from(state.features);
    updatedList[itemIndex] = updatedItem;

    state = state.copyWith(
      features: updatedList,
      statusMessage: 'Feature "${targetItem.title}" marked as declined.',
    );
  }

  Future<void> toggleVote(String featureId) async {
    final currentFeatures = state.features;
    final index = currentFeatures.indexWhere((f) => f.id == featureId);
    if (index == -1) return;

    final item = currentFeatures[index];
    final bool newHasVoted = !item.hasVoted;
    final int newVotes = newHasVoted ? item.votes + 1 : (item.votes > 0 ? item.votes - 1 : 0);

    final updatedItem = item.copyWith(
      votes: newVotes,
      hasVoted: newHasVoted,
    );

    final updatedList = List<RoadmapFeatureItem>.from(currentFeatures);
    updatedList[index] = updatedItem;

    // Optimistic UI update
    state = state.copyWith(features: updatedList);

    AppLogger.logEvent('feature_vote_toggled', {
      'feature_id': featureId,
      'has_voted': newHasVoted,
      'new_votes': newVotes,
    });

    try {
      final votedIds = await _service.getVotedFeatureIds();
      final updatedVotedIds = Set<String>.from(votedIds);
      if (newHasVoted) {
        updatedVotedIds.add(featureId);
      } else {
        updatedVotedIds.remove(featureId);
      }
      await _service.saveVotedFeatureIds(updatedVotedIds);

      final cachedVotes = await _service.getCachedVotes();
      final updatedCache = Map<String, int>.from(cachedVotes);
      updatedCache[featureId] = newVotes;
      await _service.saveCachedVotes(updatedCache);

      // Push to Cloud Firestore
      await _service.syncVoteToFirestore(updatedItem);
    } catch (e) {
      AppLogger.info('Vote persistence notice: $e');
    }
  }

  Future<void> proposeFeature({
    required String title,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final newItem = await _service.proposeFeature(
        title: title,
        description: description,
      );

      final currentList = List<RoadmapFeatureItem>.from(state.features);
      currentList.insert(0, newItem);

      state = state.copyWith(
        features: currentList,
        isLoading: false,
        statusMessage: '✨ Thank you! Your feature idea has been submitted for peaceful curator review before appearing publicly. 🙏',
      );

      AppLogger.logEvent('feature_proposed', {
        'feature_id': newItem.id,
        'title': newItem.title,
        'curator_contact': 'neilwarner+selah@gmail.com',
      });
    } catch (e) {
      AppLogger.info('Propose feature notice: $e');
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Suggestion saved locally for review. Thank you! 🙏',
      );
    }
  }
}
