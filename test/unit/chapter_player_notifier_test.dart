import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/analytics_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/logging/app_logger.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';

class _MockTestAnalytics implements AnalyticsService {
  final void Function(String event, Map<String, dynamic>? properties) onLog;
  _MockTestAnalytics(this.onLog);

  @override
  Future<void> init() async {}

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    onLog(eventName, properties);
  }

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => '/tmp');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (call) async {
            if (call.method == 'init') {
              final id = (call.arguments as Map?)?['id'] as String? ?? 'test-player';
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                  .setMockMethodCallHandler(
                    MethodChannel('com.ryanheise.just_audio.methods.$id'),
                    (playerCall) async {
                      if (playerCall.method == 'load') {
                        final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
                        const codec = StandardMethodCodec();
                        final event = <String, dynamic>{
                          'processingState': 3,
                          'updateTime': DateTime.now().millisecondsSinceEpoch,
                          'updatePosition': 0,
                          'bufferedPosition': 0,
                          'duration': 10000000,
                          'icyMetadata': null,
                          'currentIndex': 0,
                          'androidAudioSessionId': null,
                        };
                        messenger.handlePlatformMessage(
                          'com.ryanheise.just_audio.events.$id',
                          codec.encodeSuccessEnvelope(event),
                          (_) {},
                        );
                        return {'duration': 10000000};
                      }
                      if (playerCall.method == 'play') return {};
                      if (playerCall.method == 'pause') return {};
                      if (playerCall.method == 'stop') return {};
                      if (playerCall.method == 'setVolume') return {};
                      return {};
                    },
                  );
              return {'id': id};
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

    test('pause and stopAllPlayback emit playback_stopped when playing', () async {
      final loggedEvents = <Map<String, dynamic>>[];
      final mockAnalytics = _MockTestAnalytics((name, props) {
        loggedEvents.add({'event': name, ...?props});
      });
      AppLogger.init(mockAnalytics);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chapterPlayerProvider.notifier);
      await notifier.play();
      expect(container.read(chapterPlayerProvider).isPlaying, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await notifier.pause();
      expect(container.read(chapterPlayerProvider).isPlaying, isFalse);

      final pauseEvents = loggedEvents.where((e) => e['event'] == 'playback_stopped').toList();
      expect(pauseEvents, isNotEmpty);
      expect(pauseEvents.last['reason'], equals('user_pause'));
      expect(pauseEvents.last['passage'], equals(container.read(chapterPlayerProvider).currentChapter.reference));

      await notifier.play();
      expect(container.read(chapterPlayerProvider).isPlaying, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await notifier.stopAllPlayback(reason: 'user_action');
      expect(container.read(chapterPlayerProvider).isPlaying, isFalse);

      final stopEvents = loggedEvents.where((e) => e['event'] == 'playback_stopped').toList();
      expect(stopEvents.length, greaterThanOrEqualTo(2));
      expect(stopEvents.last['reason'], equals('user_action'));
    });

    test('a present_passage stop does not clear playback that started while it was pending', () async {
      final gate = _TtsStopGate()..install();
      addTearDown(gate.restore);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chapterPlayerProvider.notifier);
      await pumpEventQueue();

      final passage = PassageShareLink.tryParse('1 Cor 13:4-7');
      expect(passage, isNotNull);
      final stopsBeforeOpen = gate.stops.length;
      notifier.presentSharedPassage(passage!);
      await gate.waitForCount(stopsBeforeOpen + 1);

      final openedRequest = notifier.passageRequestId;
      final playback = notifier.play();
      await gate.waitForCount(stopsBeforeOpen + 2);
      expect(notifier.passageRequestId, greaterThan(openedRequest));

      await gate.releaseExcept(stopsBeforeOpen, until: () => container.read(chapterPlayerProvider).isPlaying);
      expect(container.read(chapterPlayerProvider).isPlaying, isTrue);

      gate.complete(stopsBeforeOpen);
      await pumpEventQueue();
      await playback;
      expect(container.read(chapterPlayerProvider).isPlaying, isTrue);
    });
  });
}

/// Holds `flutter_tts` stop calls so a newer passage request can start
/// before an older native stop returns.
class _TtsStopGate {
  final stops = <Completer<dynamic>>[];
  var _passThrough = false;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
      if (call.method == 'stop' && !_passThrough) {
        final pending = Completer<dynamic>();
        stops.add(pending);
        return pending.future;
      }
      return 1;
    });
  }

  Future<void> waitForCount(int count) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (stops.length < count) {
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out waiting for $count TTS stop calls, saw ${stops.length}');
      }
      await pumpEventQueue();
    }
  }

  /// Completes every held stop except [kept], until [until] is true.
  Future<void> releaseExcept(int kept, {required bool Function() until}) async {
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (!until()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('newer playback did not start (${stops.length} TTS stops held)');
      }
      for (var i = 0; i < stops.length; i++) {
        if (i == kept || stops[i].isCompleted) continue;
        stops[i].complete(1);
      }
      await pumpEventQueue();
    }
  }

  void complete(int index) {
    if (!stops[index].isCompleted) stops[index].complete(1);
  }

  void restore() {
    _passThrough = true;
    for (final pending in stops) {
      if (!pending.isCompleted) pending.complete(1);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1);
  }
}

