import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChapterPlayerNotifier Unit Tests', () {
    test('Initial state has featured chapter and narrator mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(chapterPlayerProvider);
      expect(state.currentChapter, isNotNull);
      expect(state.audioMode, equals(AudioMode.narrator));
      expect(state.activeTranslation, equals('BSB'));
    });

    test('Initial state respects persisted translation from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        UserPreferences.lastTranslationKey: 'NIV',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(chapterPlayerProvider);
      expect(state.activeTranslation, equals('NIV'));
      expect(state.translation, equals(BibleTranslation.niv));
    });

    test('Translation change updates active translation state to NIV and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chapterPlayerProvider.notifier);
      notifier.setTranslation('NIV');

      final state = container.read(chapterPlayerProvider);
      expect(state.activeTranslation, equals('NIV'));
      expect(state.translation, equals(BibleTranslation.niv));
      expect(prefs.getString(UserPreferences.lastTranslationKey), equals('NIV'));
    });

    test('BibleTranslation registry correctly identifies narrator coverage for OT and NT', () {
      expect(BibleTranslation.bsb.hasNarratorFor('GEN'), isTrue);
      expect(BibleTranslation.bsb.hasNarratorFor('JHN'), isTrue);
      expect(BibleTranslation.web.hasNarratorFor('GEN'), isFalse);
      expect(BibleTranslation.web.hasNarratorFor('JHN'), isTrue);
      expect(BibleTranslation.niv.hasNarratorFor('PSA'), isTrue);
      expect(BibleTranslation.niv.hasNarratorFor('JHN'), isTrue);
      expect(BibleTranslation.niv.isLicensed, isTrue);
    });
  });
}
