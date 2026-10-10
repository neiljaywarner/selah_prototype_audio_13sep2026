import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  UserPreferences(this._prefs);
  final SharedPreferences _prefs;

  static const lastTranslationKey = 'selah.last_translation';

  String? get lastTranslationCode => _prefs.getString(lastTranslationKey);

  Future<void> setLastTranslationCode(String code) => _prefs.setString(lastTranslationKey, code);
}

final userPreferencesProvider = Provider<UserPreferences>(
  (ref) => UserPreferences(ref.watch(sharedPreferencesProvider)),
);
