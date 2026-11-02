import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cache/offline_scripture_cache.dart';
import 'saved_passage.dart';

/// Overridden in `main()` with an already-loaded instance so notifiers can
/// read preferences synchronously in `build()`.
///
/// Backed by localStorage on web (PWA), NSUserDefaults on iOS and
/// SharedPreferences on Android.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

/// Typed wrapper so preference keys live in one place.
class UserPreferences {
  UserPreferences([this._prefs]);
  final SharedPreferences? _prefs;

  static const lastTranslationKey = 'selah.last_translation';

  /// Legacy mixed recents list (plain strings, silent cap of 10).
  /// Migrated once into [myPassagesKey]. New bookmarks do not write this key.
  static const savedChaptersKey = 'selah.saved_chapters';
  static const myPassagesKey = 'selah.my_passages';
  static const recentPassagesKey = 'selah.recent_passages';
  static const lastPlayedQueryKey = 'selah.last_played_query';

  /// Durable bookmarks. Saving past this cap is refused with a message;
  /// nothing is dropped silently.
  static const myPassagesCap = 40;

  /// Auto history. The oldest entry drops after this many distinct plays.
  static const recentPassagesCap = 12;

  String? get lastTranslationCode => _prefs?.getString(lastTranslationKey);

  Future<void> setLastTranslationCode(String code) async => _prefs?.setString(lastTranslationKey, code);

  /// Exact query of the last passage the user asked to play.
  ///
  /// Not autoplayed on launch: browsers block autoplay, and starting audio
  /// unprompted would surprise someone opening Selah. The Recent row keeps
  /// this query at the front for an explicit tap.
  String? get lastPlayedQuery {
    final raw = _prefs?.getString(lastPlayedQueryKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final query = PassageQuery.canonicalize(raw);
    return query.isEmpty ? null : query;
  }

  /// Durable "My passages". Falls back to the legacy recents list until
  /// [migrateLegacySavedChapters] has copied them.
  List<SavedPassage> get myPassages => _readPassages(myPassagesKey, includeLegacy: true);

  /// Auto history, newest first. Separate from [myPassages] so playing
  /// something cannot evict a bookmark.
  List<SavedPassage> get recentPassages => _readPassages(recentPassagesKey, includeLegacy: false);

  List<SavedPassage> _readPassages(String key, {required bool includeLegacy}) {
    final prefs = _prefs;
    if (prefs == null) return const [];
    final stored = prefs.getStringList(key);
    if (stored != null) {
      return _decodeList(stored);
    }
    if (!includeLegacy || prefs.containsKey(key)) return const [];
    return _decodeList(prefs.getStringList(savedChaptersKey) ?? const []);
  }

  List<SavedPassage> _decodeList(List<String> raw) {
    final out = <SavedPassage>[];
    for (final item in raw) {
      final decoded = SavedPassage.tryDecode(item);
      if (decoded == null) continue;
      if (out.any((p) => p.query.toLowerCase() == decoded.query.toLowerCase())) continue;
      out.add(decoded);
    }
    return out;
  }

  Future<void> _writePassages(String key, List<SavedPassage> passages) async {
    await _prefs?.setStringList(key, passages.map((p) => p.encode()).toList());
  }

  /// Copies the old 10-item recents list into My passages once.
  Future<void> migrateLegacySavedChapters() async {
    final prefs = _prefs;
    if (prefs == null || prefs.containsKey(myPassagesKey)) return;
    final legacy = _decodeList(prefs.getStringList(savedChaptersKey) ?? const []);
    await prefs.setStringList(myPassagesKey, legacy.map((p) => p.encode()).toList());
  }

  Future<SavePassageResult> saveMyPassage(SavedPassage passage) async {
    final prefs = _prefs;
    if (prefs == null) return SavePassageResult.unavailable;
    await migrateLegacySavedChapters();
    final query = PassageQuery.canonicalize(passage.query);
    if (query.isEmpty) return SavePassageResult.unavailable;
    final label = passage.label.trim().isEmpty ? query : passage.label.trim();
    final list = List<SavedPassage>.from(myPassages);
    final index = list.indexWhere((p) => p.query.toLowerCase() == query.toLowerCase());
    if (index >= 0) {
      final existing = list.removeAt(index);
      list.insert(0, existing);
      await _writePassages(myPassagesKey, list);
      return SavePassageResult.alreadySaved;
    }
    if (list.length >= myPassagesCap) return SavePassageResult.full;
    list.insert(0, SavedPassage(query: query, label: label));
    await _writePassages(myPassagesKey, list);
    return SavePassageResult.saved;
  }

  /// Changes the chip label. The stored [query] stays the replay key.
  Future<bool> renameMyPassage(String query, String newLabel) async {
    final prefs = _prefs;
    if (prefs == null) return false;
    await migrateLegacySavedChapters();
    final label = newLabel.trim();
    if (label.isEmpty) return false;
    final canonical = PassageQuery.canonicalize(query);
    final list = List<SavedPassage>.from(myPassages);
    final index = list.indexWhere((p) => p.query.toLowerCase() == canonical.toLowerCase());
    if (index < 0) return false;
    list[index] = SavedPassage(query: list[index].query, label: label);
    await _writePassages(myPassagesKey, list);
    return true;
  }

  Future<void> removeMyPassage(String query) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await migrateLegacySavedChapters();
    final canonical = PassageQuery.canonicalize(query);
    final list = List<SavedPassage>.from(myPassages)
      ..removeWhere((p) => p.query.toLowerCase() == canonical.toLowerCase());
    await _writePassages(myPassagesKey, list);
  }

  /// Records a play in Recent and remembers it as last-played.
  ///
  /// History is capped at [recentPassagesCap]. My passages is untouched.
  Future<void> recordRecent(String raw) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final query = PassageQuery.canonicalize(raw);
    if (query.isEmpty) return;
    await prefs.setString(lastPlayedQueryKey, query);
    final list = List<SavedPassage>.from(recentPassages)
      ..removeWhere((p) => p.query.toLowerCase() == query.toLowerCase());
    list.insert(0, SavedPassage(query: query, label: query));
    if (list.length > recentPassagesCap) {
      list.removeRange(recentPassagesCap, list.length);
    }
    await _writePassages(recentPassagesKey, list);
  }

  Future<void> removeRecent(String query) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final canonical = PassageQuery.canonicalize(query);
    final list = List<SavedPassage>.from(recentPassages)
      ..removeWhere((p) => p.query.toLowerCase() == canonical.toLowerCase());
    await _writePassages(recentPassagesKey, list);
  }
  static const experimentalApiBibleNarratorKey = 'selah.experimental_api_bible_narrator';

  bool get experimentalApiBibleNarrator =>
      _prefs?.getBool(experimentalApiBibleNarratorKey) ?? false;

  Future<void> setExperimentalApiBibleNarrator(bool value) async =>
      _prefs?.setBool(experimentalApiBibleNarratorKey, value);

  static const showWorkInProgressFeaturesKey = 'selah.show_work_in_progress_features';

  bool get showWorkInProgressFeatures =>
      _prefs?.getBool(showWorkInProgressFeaturesKey) ?? false;

  Future<void> setShowWorkInProgressFeatures(bool value) async =>
      _prefs?.setBool(showWorkInProgressFeaturesKey, value);

  static const catalogTierKey = 'selah.catalog_tier';

  CatalogTier get catalogTier {
    final raw = _prefs?.getString(catalogTierKey);
    return CatalogTier.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CatalogTier.biblical40,
    );
  }

  Future<void> setCatalogTier(CatalogTier tier) async =>
      _prefs?.setString(catalogTierKey, tier.name);

  SharedPreferences? get prefs => _prefs;
}

enum CatalogTier {
  curated12('Curated 12', 'Core foundation (12 passages)', '🌿'),
  biblical40('Biblical 40', 'Wilderness & Peace cohort (40 passages)', '📜'),
  softLaunch77('The 77 Cohort', 'Beta Meditators dedicated cohort (77 passages)', '🕊️'),
  allPassages('All 66 Books', 'Full Scripture library & arbitrary passages', '📖');

  const CatalogTier(this.label, this.description, this.emoji);
  final String label;
  final String description;
  final String emoji;
}

final userPreferencesProvider = Provider<UserPreferences>(
  (ref) {
    try {
      return UserPreferences(ref.watch(sharedPreferencesProvider));
    } catch (_) {
      return UserPreferences(null);
    }
  },
);

final offlineScriptureCacheProvider = Provider<OfflineScriptureCache>(
  (ref) => OfflineScriptureCache(ref.watch(userPreferencesProvider).prefs),
);

class WorkInProgressFeaturesNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(userPreferencesProvider).showWorkInProgressFeatures;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(userPreferencesProvider).setShowWorkInProgressFeatures(enabled);
  }
}

final workInProgressFeaturesProvider =
    NotifierProvider<WorkInProgressFeaturesNotifier, bool>(
  WorkInProgressFeaturesNotifier.new,
);

class CatalogTierNotifier extends Notifier<CatalogTier> {
  @override
  CatalogTier build() {
    return ref.watch(userPreferencesProvider).catalogTier;
  }

  Future<void> setTier(CatalogTier tier) async {
    state = tier;
    await ref.read(userPreferencesProvider).setCatalogTier(tier);
  }
}

final catalogTierProvider = NotifierProvider<CatalogTierNotifier, CatalogTier>(
  CatalogTierNotifier.new,
);
