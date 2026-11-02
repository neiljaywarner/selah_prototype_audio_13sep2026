import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/saved_passage.dart';
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

    test('Recent history is capped without evicting My passages', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userPrefs = UserPreferences(prefs);

      expect(userPrefs.myPassages, isEmpty);
      expect(userPrefs.recentPassages, isEmpty);

      final saved = await userPrefs.saveMyPassage(
        const SavedPassage(query: '1 Cor 13:4-7', label: '1 Cor 13:4-7'),
      );
      expect(saved, SavePassageResult.saved);

      await userPrefs.recordRecent('Psalms 126');
      await userPrefs.recordRecent('Philippians 4');
      expect(userPrefs.recentPassages.map((p) => p.query), ['Philippians 4', 'Psalms 126']);

      await userPrefs.recordRecent('Psalms 126');
      expect(userPrefs.recentPassages.map((p) => p.query), ['Psalms 126', 'Philippians 4']);

      for (var i = 1; i <= 20; i++) {
        await userPrefs.recordRecent('Psalm $i');
      }
      expect(userPrefs.recentPassages.length, UserPreferences.recentPassagesCap);
      expect(userPrefs.recentPassages.first.query, 'Psalm 20');
      expect(userPrefs.myPassages.map((p) => p.query), ['1 Cor 13:4-7']);
      expect(userPrefs.lastPlayedQuery, 'Psalm 20');
    });

    test('cycleRepetitions transitions from 1 -> 3 -> 7 -> infinite (-1) -> 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chapterPlayerProvider.notifier);
      expect(container.read(chapterPlayerProvider).repetitions, equals(3));

      // 3 -> 7
      notifier.cycleRepetitions();
      expect(container.read(chapterPlayerProvider).repetitions, equals(7));

      // 7 -> -1 (infinite)
      notifier.cycleRepetitions();
      expect(container.read(chapterPlayerProvider).repetitions, equals(-1));

      // -1 -> 1
      notifier.cycleRepetitions();
      expect(container.read(chapterPlayerProvider).repetitions, equals(1));

      // 1 -> 3
      notifier.cycleRepetitions();
      expect(container.read(chapterPlayerProvider).repetitions, equals(3));
    });
  });
}

