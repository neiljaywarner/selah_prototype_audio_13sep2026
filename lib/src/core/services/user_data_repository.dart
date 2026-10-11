abstract class ScriptureUserDataRepository {
  Future<List<String>> getFavoritePassages(String userId);
  Future<void> toggleFavoritePassage(String userId, String passageRef);
  Future<void> saveMeditationSession({
    required String userId,
    required String reference,
    required int completedLoops,
    required int durationSeconds,
  });
}

class InMemoryScriptureUserDataRepository implements ScriptureUserDataRepository {
  final Set<String> _favorites = {'PSA.23', 'COL.1'};

  @override
  Future<List<String>> getFavoritePassages(String userId) async {
    return _favorites.toList();
  }

  @override
  Future<void> toggleFavoritePassage(String userId, String passageRef) async {
    if (_favorites.contains(passageRef)) {
      _favorites.remove(passageRef);
    } else {
      _favorites.add(passageRef);
    }
  }

  @override
  Future<void> saveMeditationSession({
    required String userId,
    required String reference,
    required int completedLoops,
    required int durationSeconds,
  }) async {
    // Session recorded in memory
  }
}
