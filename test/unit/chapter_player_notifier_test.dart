import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (call) async {
            if (call.method == 'init') {
              return {'id': 'test-player'};
            }
            if (call.method == 'load') {
              return {'duration': 10000000};
            }
            return {};
          },
        );
  });

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

    test('Translation shuffle cycles through BSB, WEB, and NIV', () async {
      final container = ProviderContainer();

      final notifier = container.read(chapterPlayerProvider.notifier);
      expect(container.read(chapterPlayerProvider).shuffleTranslations, isFalse);
      expect(container.read(chapterPlayerProvider).activeTranslation, equals('BSB'));

      // Toggling shuffle on enables shuffle and immediately cycles to next translation (WEB)
      notifier.toggleShuffleTranslations();
      expect(container.read(chapterPlayerProvider).shuffleTranslations, isTrue);
      expect(container.read(chapterPlayerProvider).activeTranslation, equals('WEB'));

      // Cycling next translation advances to NIV
      notifier.cycleNextTranslation();
      expect(container.read(chapterPlayerProvider).activeTranslation, equals('NIV'));

      // Cycling next translation wraps around to BSB
      notifier.cycleNextTranslation();
      expect(container.read(chapterPlayerProvider).activeTranslation, equals('BSB'));

      // Toggling shuffle off disables shuffle
      notifier.toggleShuffleTranslations();
      expect(container.read(chapterPlayerProvider).shuffleTranslations, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      container.dispose();
    });

    test('UserPreferences LIFO queue saves chapters at front and enforces cap', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userPrefs = UserPreferences(prefs);

      expect(userPrefs.savedChapters, isEmpty);

      await userPrefs.saveChapter('Psalms 126');
      expect(userPrefs.savedChapters, equals(['Psalms 126']));

      await userPrefs.saveChapter('Philippians 4');
      expect(userPrefs.savedChapters, equals(['Philippians 4', 'Psalms 126']));

      // Re-saving existing chapter moves it to index 0 (LIFO MRU)
      await userPrefs.saveChapter('Psalms 126');
      expect(userPrefs.savedChapters, equals(['Psalms 126', 'Philippians 4']));

      // Test cap of 10 items
      for (int i = 1; i <= 15; i++) {
        await userPrefs.saveChapter('Chapter $i');
      }
      expect(userPrefs.savedChapters.length, equals(10));
      expect(userPrefs.savedChapters.first, equals('Chapter 15'));

      await userPrefs.removeSavedChapter('Chapter 15');
      expect(userPrefs.savedChapters.contains('Chapter 15'), isFalse);
      expect(userPrefs.savedChapters.length, equals(9));
    });
  });
}

