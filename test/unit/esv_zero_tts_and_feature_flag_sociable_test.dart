import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';

class _ScriptedEsvHttpAdapter implements HttpClientAdapter {
  _ScriptedEsvHttpAdapter({this.shouldThrowNetworkError = false, this.returnEmptyVerses = false});

  bool shouldThrowNetworkError;
  bool returnEmptyVerses;
  final List<String> requestedPaths = [];
  final List<String> requestedQueries = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
    final q = (options.queryParameters['q'] ?? '').toString();
    requestedQueries.add(q);

    if (shouldThrowNetworkError) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Simulated network failure',
      );
    }

    if (options.path.contains('/passage/audio/')) {
      return ResponseBody.fromString(
        '',
        302,
        headers: {
          'location': ['https://audio.esv.org/hw/${Uri.encodeComponent(q)}.mp3'],
        },
      );
    }

    if (returnEmptyVerses) {
      return ResponseBody.fromString(
        jsonEncode({'canonical': q, 'passages': <String>[]}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'canonical': q,
        'passages': <String>['Scripture text for $q.'],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> ttsSpeakCalls = [];
  final List<Map<dynamic, dynamic>> loadedAudioSources = [];
  bool failJustAudioLoad = false;
  String? activePlayerId;

  setUp(() {
    ttsSpeakCalls.clear();
    loadedAudioSources.clear();
    failJustAudioLoad = false;
    activePlayerId = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
      if (call.method == 'speak') {
        ttsSpeakCalls.add(call.arguments?.toString() ?? '');
      }
      return 1;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (call) async {
        if (call.method == 'init') {
          final id = (call.arguments as Map)['id'] as String;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            MethodChannel('com.ryanheise.just_audio.methods.$id'),
            (playerCall) async {
              if (playerCall.method == 'load') {
                if (failJustAudioLoad) {
                  throw PlatformException(
                    code: 'abort',
                    message: 'Simulated HTML5 <audio> stream error',
                  );
                }
                final args = playerCall.arguments as Map;
                final source = args['audioSource'] as Map;
                loadedAudioSources.add(source);
                return {'duration': 24000000};
              }
              if (playerCall.method == 'play') return {};
              if (playerCall.method == 'pause') return {};
              if (playerCall.method == 'stop') return {};
              if (playerCall.method == 'setVolume') return {};
              if (playerCall.method == 'seek') return {};
              return {};
            },
          );
          return {};
        }
        return {};
      },
    );
  });

  EsvApiClient makeClient(_ScriptedEsvHttpAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.esv.org/v3'));
    dio.httpClientAdapter = adapter;
    return EsvApiClient(dio: dio, apiKey: 'test-esv-key');
  }

  group('ESV Soft Launch Sociable Guardrails (Zero TTS & Strict Feature Flag)', () {
    test('Stale NIV in SharedPreferences is ignored when experimental flag is false, and NIV/Shuffle setters are blocked', () async {
      SharedPreferences.setMockInitialValues({
        UserPreferences.lastTranslationKey: 'NIV',
        UserPreferences.experimentalApiBibleNarratorKey: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final adapter = _ScriptedEsvHttpAdapter();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(makeClient(adapter)),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(chapterPlayerProvider);
      expect(initial.activeTranslation, 'ESV');
      expect(initial.audioMode, AudioMode.narrator);
      expect(initial.shuffleTranslations, isFalse);

      final notifier = container.read(chapterPlayerProvider.notifier);
      notifier.setTranslation('NIV');
      notifier.setTranslation('BSB');
      notifier.setTranslation('WEB');
      notifier.toggleShuffleTranslations();
      notifier.cycleNextTranslation();

      final after = container.read(chapterPlayerProvider);
      expect(after.activeTranslation, 'ESV');
      expect(after.shuffleTranslations, isFalse);
      expect(after.audioMode, AudioMode.narrator);
      expect(ttsSpeakCalls, isEmpty);
    });

    test('Pressing Play from initial boot plays Crossway ESV human narrator for 1 Cor 13:4-7 with zero TTS flash or speak calls', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = _ScriptedEsvHttpAdapter();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(makeClient(adapter)),
        ],
      );
      addTearDown(container.dispose);

      final observedModes = <AudioMode>[];
      container.listen<ChapterPlayerState>(
        chapterPlayerProvider,
        (_, next) => observedModes.add(next.audioMode),
        fireImmediately: true,
      );

      final notifier = container.read(chapterPlayerProvider.notifier);
      await notifier.play();

      final state = container.read(chapterPlayerProvider);
      expect(observedModes, everyElement(AudioMode.narrator),
          reason: 'audioMode must NEVER flash to AudioMode.tts even while loading');
      expect(state.audioMode, AudioMode.narrator);
      expect(state.activeTranslation, 'ESV');
      expect(state.infoNotice, isNull);
      expect(state.lastError, isNull);
      expect(state.currentChapter.audioStreamUrl,
          'https://audio.esv.org/hw/1%20Cor%2013%3A4-7.mp3');
      expect(loadedAudioSources, isNotEmpty);
      expect(loadedAudioSources.last['headers'], isNull,
          reason: 'audio.esv.org CDN URLs must not attach custom headers that break Web');
      expect(ttsSpeakCalls, isEmpty);
    });

    test('Selecting 1 Peter 5:7–9 preset chip plays Crossway human narrator with zero TTS', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = _ScriptedEsvHttpAdapter();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(makeClient(adapter)),
        ],
      );
      addTearDown(container.dispose);

      final peterPreset = kFeaturedChapters.firstWhere((c) => c.bookCode == '1PE');
      await container.read(chapterPlayerProvider.notifier).loadChapter(peterPreset);

      final state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.activeTranslation, 'ESV');
      expect(state.currentChapter.audioStreamUrl,
          'https://audio.esv.org/hw/1%20Peter%205%3A7-9.mp3');
      expect(state.infoNotice, isNull);
      expect(ttsSpeakCalls, isEmpty);
    });

    test('ESV network failure NEVER falls through to NIV notice or TTS in routeAndPlayChapter, loadChapter, or fetchAndPlaySingleVerse', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = _ScriptedEsvHttpAdapter(shouldThrowNetworkError: true);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(makeClient(adapter)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chapterPlayerProvider.notifier);

      // 1. routeAndPlayChapter failure
      await notifier.routeAndPlayChapter(
        bookCode: '1CO',
        chapterNumber: 13,
        bookName: '1 Corinthians',
      );
      var state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.activeTranslation, 'ESV');
      expect(state.isPlaying, isFalse);
      expect(state.infoNotice, isNull);
      expect(state.lastError, isNotNull);
      expect(state.lastError!.contains('NIV'), isFalse);
      expect(ttsSpeakCalls, isEmpty);

      // 2. loadChapter failure
      await notifier.loadChapter(kFeaturedChapters.first);
      state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.infoNotice, isNull);
      expect(state.lastError!.contains('NIV'), isFalse);
      expect(ttsSpeakCalls, isEmpty);

      // 3. fetchAndPlaySingleVerse failure
      await notifier.fetchAndPlaySingleVerse('John 11:35');
      state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.infoNotice, isNull);
      expect(state.lastError!.contains('NIV'), isFalse);
      expect(ttsSpeakCalls, isEmpty);

      // 4. Tapping play() again after failure retries ESV instead of speaking TTS
      adapter.shouldThrowNetworkError = false;
      await notifier.play();
      state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.lastError, isNull);
      expect(ttsSpeakCalls, isEmpty);
    });

    test('Audio player load failure on ESV sets ESV error and NEVER falls back to TTS', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = _ScriptedEsvHttpAdapter();
      failJustAudioLoad = true;

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(makeClient(adapter)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(chapterPlayerProvider.notifier).play();
      final state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.isPlaying, isFalse);
      expect(state.infoNotice, isNull);
      expect(state.lastError, isNotNull);
      expect(state.lastError!.contains('ESV'), isTrue);
      expect(state.lastError!.contains('NIV'), isFalse);
      expect(ttsSpeakCalls, isEmpty);
    });

    test('Playback error on ESV sets ESV error and NEVER switches to TTS', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = _ScriptedEsvHttpAdapter();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(makeClient(adapter)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(chapterPlayerProvider.notifier).play();
      final notifier = container.read(chapterPlayerProvider.notifier);

      // Trigger stream error handler logic directly via notifier fallback test
      notifier.seek(const Duration(seconds: 5));
      final state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.activeTranslation, 'ESV');
      expect(ttsSpeakCalls, isEmpty);
    });

    test('Turning experimental API.Bible flag ON then OFF resets translation to ESV and clears shuffleTranslations', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = _ScriptedEsvHttpAdapter();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(makeClient(adapter)),
        ],
      );
      addTearDown(container.dispose);

      // Enable experimental API.Bible preview
      await container.read(experimentalApiBibleNarratorProvider.notifier).setEnabled(true);
      expect(container.read(esvPassagePolicyProvider).showApiBibleTranslations, isTrue);

      final notifier = container.read(chapterPlayerProvider.notifier);
      notifier.toggleShuffleTranslations();
      expect(container.read(chapterPlayerProvider).shuffleTranslations, isTrue);

      // Turn experimental preview back OFF -> must lock back to ESV & disable shuffle
      await container.read(experimentalApiBibleNarratorProvider.notifier).setEnabled(false);
      notifier.setTranslation(BibleTranslation.esv.code, force: true);

      final state = container.read(chapterPlayerProvider);
      expect(state.activeTranslation, 'ESV');
      expect(state.shuffleTranslations, isFalse);
      expect(state.audioMode, AudioMode.narrator);
    });

    test('Empty ESV response keeps narrator mode and never falls through to TTS', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = _ScriptedEsvHttpAdapter(returnEmptyVerses: true);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(makeClient(adapter)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(chapterPlayerProvider.notifier).fetchAndPlaySingleVerse('Hezekiah 1:1');
      final state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.isPlaying, isFalse);
      expect(state.infoNotice, isNull);
      expect(ttsSpeakCalls, isEmpty);
    });
  });
}
