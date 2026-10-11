import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cache/offline_scripture_cache.dart';

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
  static const savedChaptersKey = 'selah.saved_chapters';

  String? get lastTranslationCode => _prefs?.getString(lastTranslationKey);

  Future<void> setLastTranslationCode(String code) async => _prefs?.setString(lastTranslationKey, code);

  /// LIFO queue of manually added/saved chapters
  List<String> get savedChapters => _prefs?.getStringList(savedChaptersKey) ?? const [];

  /// Add a chapter to the front of the LIFO queue (capped at 10 items)
  Future<void> saveChapter(String ref) async {
    if (_prefs == null) return;
    final list = List<String>.from(_prefs!.getStringList(savedChaptersKey) ?? const []);
    list.remove(ref);
    list.insert(0, ref);
    if (list.length > 10) list.removeLast();
    await _prefs!.setStringList(savedChaptersKey, list);
  }

  Future<void> removeSavedChapter(String ref) async {
    if (_prefs == null) return;
    final list = List<String>.from(_prefs!.getStringList(savedChaptersKey) ?? const []);
    list.remove(ref);
    await _prefs!.setStringList(savedChaptersKey, list);
  }
  SharedPreferences? get prefs => _prefs;
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
