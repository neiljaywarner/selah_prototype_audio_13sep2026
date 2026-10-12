import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/app_logger.dart';
import 'feature_voting_service.dart';

class FeatureVotingState {
  final List<RoadmapFeatureItem> features;
  final bool isLoading;
  final String? statusMessage;

  const FeatureVotingState({
    required this.features,
    this.isLoading = false,
    this.statusMessage,
  });

  FeatureVotingState copyWith({
    List<RoadmapFeatureItem>? features,
    bool? isLoading,
    String? statusMessage,
    bool clearStatus = false,
  }) {
    return FeatureVotingState(
      features: features ?? this.features,
      isLoading: isLoading ?? this.isLoading,
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
    );
  }

  Future<void> loadFeatures() async {
    state = state.copyWith(isLoading: true);
    try {
      final remoteFeatures = await _service.fetchFeatures();
      final votedIds = await _service.getVotedFeatureIds();
      final merged = remoteFeatures.map((f) {
        final hasVoted = votedIds.contains(f.id);
        return f.copyWith(hasVoted: hasVoted);
      }).toList();
      state = state.copyWith(features: merged, isLoading: false);
    } catch (e) {
      AppLogger.info('Feature voting loadNotice: $e');
      state = state.copyWith(isLoading: false);
    }
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
      currentList.sort((a, b) => b.votes.compareTo(a.votes));

      state = state.copyWith(
        features: currentList,
        isLoading: false,
        statusMessage: 'Thank you! Your feature suggestion has been added to the community roadmap. 🙏',
      );

      AppLogger.logEvent('feature_proposed', {
        'feature_id': newItem.id,
        'title': newItem.title,
      });
    } catch (e) {
      AppLogger.info('Propose feature notice: $e');
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Suggestion saved locally. Thank you! 🙏',
      );
    }
  }
}
