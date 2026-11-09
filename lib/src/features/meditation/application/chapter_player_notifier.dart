import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../core/audio/bundled_audio_service.dart';
import '../../../core/cache/public_domain_passage_text.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/bible_canon.dart';
import '../../../core/esv/esv_api_client.dart';
import '../../../core/esv/esv_passage_policy.dart';
import '../../../core/karaoke/timestamp_loader.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/preferences/user_preferences.dart';
import '../../../core/remote_config/remote_config_service.dart';
import '../domain/audio_mode.dart';
import '../domain/bible_translation.dart';
import '../domain/chapter_info.dart';
import '../domain/passage_audio_route.dart';
import '../domain/passage_excerpt.dart';
import '../domain/passage_share.dart';
export 'chapter_player_state.dart';
import 'chapter_player_state.dart';

final chapterPlayerProvider = NotifierProvider<ChapterPlayerNotifier, ChapterPlayerState>(
  ChapterPlayerNotifier.new,
);

class ChapterPlayerNotifier extends Notifier<ChapterPlayerState> {
  late AudioPlayer _audioPlayer;
  late FlutterTts _flutterTts;
  late Dio _dio;
  Timer? _gapTimer;
  Timer? _sleepTimer;
  Timer? _volumeFadeTimer;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _eventSub;
  StreamSubscription? _stateSub;
  List<VerseTimestamp>? _currentTimestamps;

  /// Start of the active clip within the full chapter stream. Player positions
  /// are clip-relative, while timestamps are chapter-absolute.
  Duration _clipOffset = Duration.zero;

  DateTime? _playStartTime;
  int _accumulatedSeconds = 0;
  int _sessionTotalSeconds = 0;
  bool _cycleCompletedForCurrentIteration = false;

  void _recordListeningStart() {
    _playStartTime = DateTime.now();
    _cycleCompletedForCurrentIteration = false;
  }

  int _computeAndResetSecondsListened() {
    int total = _accumulatedSeconds;
    if (_playStartTime != null) {
      total += DateTime.now().difference(_playStartTime!).inSeconds;
      _playStartTime = null;
    }
    _accumulatedSeconds = 0;
    final clamped = total.clamp(0, 86400);
    _sessionTotalSeconds += clamped;
    return clamped;
  }

  int _pauseSecondsListened() {
    if (_playStartTime != null) {
      _accumulatedSeconds += DateTime.now().difference(_playStartTime!).inSeconds;
      _playStartTime = null;
    }
    // Return accumulated seconds if >= 1, or at least 1 second if playback was active
    return _accumulatedSeconds.clamp(0, 86400);
  }

  int _resetSessionSeconds() {
    final total = _sessionTotalSeconds;
    _sessionTotalSeconds = 0;
    _accumulatedSeconds = 0;
    _playStartTime = null;
    return total.clamp(0, 86400);
  }

  bool get _isEsvModeActive {
    final esv = ref.read(esvApiClientProvider);
    final policy = ref.read(esvPassagePolicyProvider);
    return policy.useEsvForPassages ||
        (esv.isConfigured && state.activeTranslation == BibleTranslation.esv.code);
  }

  String _getActiveApiKey() {
    try {
      final remoteKey = sanitizeEnvSecret(
        ref.read(remoteConfigServiceProvider).getString('api_bible_key'),
      );
      if (remoteKey.isNotEmpty) return remoteKey;
    } catch (_) {}
    return sanitizedApiBibleKey;
  }

  @override
  ChapterPlayerState build() {
    _audioPlayer = AudioPlayer();
    _flutterTts = FlutterTts();
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBibleBaseUrl,
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final activeKey = _getActiveApiKey();
          if (activeKey.isNotEmpty) {
            options.headers['api-key'] = activeKey;
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          AppLogger.info('Dio network notice: ${e.message}');
          return handler.next(e);
        },
      ),
    );

    _initAudioListeners();
    _initTtsEngine();
    _initAudioSession();

    ref.onDispose(() {
      _posSub?.cancel();
      _durSub?.cancel();
      _stateSub?.cancel();
      _eventSub?.cancel();
      _gapTimer?.cancel();
      _sleepTimer?.cancel();
      _volumeFadeTimer?.cancel();
      _audioPlayer.dispose();
      _flutterTts.stop().catchError((_) => 0);
    });

    final policy = ref.read(esvPassagePolicyProvider);
    String initialTranslation = policy.defaultTranslationCode;
    try {
      final userPrefs = ref.read(userPreferencesProvider);
      final saved = userPrefs.lastTranslationCode;
      if (saved != null && saved.isNotEmpty) {
        final savedCode = BibleTranslation.fromCode(saved).code;
        if (policy.showApiBibleTranslations || savedCode == BibleTranslation.esv.code) {
          initialTranslation = savedCode;
        }
      }
    } catch (_) {
      // In tests or if provider not yet overridden, fall back cleanly
    }

    return ChapterPlayerState(
      currentChapter: kFeaturedChapters[0],
      activeTranslation: initialTranslation,
    );
  }

  Future<void> _initAudioSession() async {
    if (!kIsWeb &&
        (Platform.environment.containsKey('FLUTTER_TEST') ||
            Platform.resolvedExecutable.contains('flutter_tester'))) {
      return;
    }
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      session.becomingNoisyEventStream.listen((_) {
        AppLogger.info('Audio becoming noisy (headphones/BT disconnected); pausing playback');
        pause();
      });
      AppLogger.info('AudioSession configured with Music profile for background audio playback.');
    } catch (e) {
      AppLogger.warning('AudioSession configuration notice: $e');
    }
  }

  void _initAudioListeners() {
    _posSub = _audioPlayer.positionStream.listen((pos) {
      if (state.audioMode == AudioMode.narrator) {
        int hStart = 0;
        int hEnd = 0;
        if (_currentTimestamps != null && _currentTimestamps!.isNotEmpty) {
          final posMs = pos.inMilliseconds + _clipOffset.inMilliseconds;
          for (final vt in _currentTimestamps!) {
            if (posMs >= vt.startMs && posMs <= vt.endMs) {
              final fullText = state.currentChapter.textContent;
              final idx = fullText.indexOf(vt.text);
              if (idx != -1) {
                hStart = idx;
                hEnd = idx + vt.text.length;
              } else {
                hStart = 0;
                hEnd = 0;
              }
              break;
            }
          }
        }
        state = state.copyWith(
          position: pos,
          highlightStart: hEnd > hStart ? hStart : 0,
          highlightEnd: hEnd > hStart ? hEnd : 0,
        );
      }
    });

    _durSub = _audioPlayer.durationStream.listen((dur) {
      if (dur != null && state.audioMode == AudioMode.narrator) {
        state = state.copyWith(duration: dur);
      }
    });

    _stateSub = _audioPlayer.playerStateStream.listen((playerState) {
      if (state.audioMode != AudioMode.narrator) return;

      final pStateStr = playerState.processingState.toString().split('.').last;
      state = state.copyWith(isPlaying: playerState.playing, processingStateName: pStateStr);

      if (playerState.processingState == ProcessingState.completed &&
          !state.isPausedInGap &&
          !_cycleCompletedForCurrentIteration) {
        _cycleCompletedForCurrentIteration = true;
        AppLogger.info('Chapter completed iteration ${state.currentIteration}');
        _handleChapterPlaybackComplete();
      }
    });

    _eventSub = _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stack) {
        if (state.audioMode == AudioMode.narrator) {
          AppLogger.error(
            'Audio stream playback error',
            error: e,
            stackTrace: stack,
            properties: {
              'book_code': state.currentChapter.bookCode,
              'chapter': state.currentChapter.chapterNumber,
              'translation': state.activeTranslation,
              'audio_mode': state.audioMode.name,
            },
          );
          if (state.currentChapter.audioStreamUrl.startsWith('assets/')) {
            AppLogger.info('Attempting recovery of bundled narrator asset after playback error');
            loadChapter(state.currentChapter);
          } else if (_isEsvModeActive) {
            _audioPlayer.stop().catchError((_) {});
            state = state.copyWith(
              audioMode: AudioMode.narrator,
              isPlaying: false,
              isLoading: false,
              clearInfoNotice: true,
              lastError:
                  'ESV human narrator audio stream unavailable. Please check your connection and tap Play to retry.',
            );
          } else {
            _switchToTtsFallback(
              'Audio stream blocked or unavailable. Switched to Text-to-Speech (TTS).',
            );
          }
        }
      },
    );
  }

  Future<void> _initTtsEngine() async {
    try {
      // 1. Prioritize Google Text-to-Speech / Speech Services on Android
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final dynamic engines = await _flutterTts.getEngines;
          if (engines is List && engines.contains('com.google.android.tts')) {
            await _flutterTts.setEngine('com.google.android.tts');
            AppLogger.info('TTS: Selected Google Text-to-Speech engine (com.google.android.tts)');
          }
        } catch (e) {
          AppLogger.info('TTS engine query notice: $e');
        }
      }

      await _flutterTts.setLanguage('en-US');

      // 2. Calibrated contemplative prosody:
      // Pacing calibrated at ~0.44 (avoids mechanical vowel stretching while preserving meditative space)
      await _flutterTts.setSpeechRate(kIsWeb ? 0.46 : 0.44);
      await _flutterTts.setPitch(1.0);

      // 3. Intelligent natural / neural voice selection
      try {
        final dynamic rawVoices = await _flutterTts.getVoices;
        if (rawVoices is List && rawVoices.isNotEmpty) {
          final List<Map<String, String>> voices = [];
          for (final v in rawVoices) {
            if (v is Map) {
              final name = v['name']?.toString() ?? '';
              final locale = v['locale']?.toString() ?? '';
              if (name.isNotEmpty) {
                voices.add({'name': name, 'locale': locale});
              }
            }
          }

          // Preferred natural & neural contemplative voice patterns
          const preferredPatterns = [
            'natural',     // Edge / Modern Web Neural Voices
            'google us',   // Chrome Google US English
            'samantha',    // iOS / macOS warm narrator
            'sfg-network', // Android Google TTS Neural Voice
            'tpd-network', // Android Google TTS Neural Voice
            'iob-network', // Android Google TTS Neural Voice
            'sfg-local',   // Android Google TTS Enhanced Local
            'iol-local',   // Android Google TTS Enhanced Local
            'en-us-x-',    // Android Google TTS English Family
          ];

          Map<String, String>? selected;
          for (final pattern in preferredPatterns) {
            for (final v in voices) {
              final vName = v['name']?.toLowerCase() ?? '';
              final vLocale = v['locale']?.toLowerCase() ?? '';
              if (vLocale.startsWith('en') && vName.contains(pattern)) {
                selected = v;
                break;
              }
            }
            if (selected != null) break;
          }

          if (selected != null) {
            await _flutterTts.setVoice({
              'name': selected['name']!,
              if (selected['locale']!.isNotEmpty) 'locale': selected['locale']!,
            });
            AppLogger.info('TTS: Selected natural contemplative voice: ${selected['name']} (${selected['locale']})');
          }
        }
      } catch (e) {
        AppLogger.info('TTS voice selection notice: $e');
      }

      _flutterTts.setProgressHandler((String text, int start, int end, String word) {
        if (state.isPlaying && state.audioMode == AudioMode.tts) {
          state = state.copyWith(highlightStart: start, highlightEnd: end);
        }
      });

      _flutterTts.setCompletionHandler(() {
        if (state.audioMode == AudioMode.tts && state.isPlaying) {
          _handleChapterPlaybackComplete();
        }
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        if (state.audioMode == AudioMode.tts && state.isPlaying) {
          AppLogger.error('TTS speech engine error: $msg');
          state = state.copyWith(isPlaying: false, lastError: 'TTS playback error: $msg');
        }
      });
    } catch (e) {
      AppLogger.info('TTS engine notice: $e');
    }
  }

  String _fallbackChapterText(
    String bookCode,
    int chapterNumber,
    String bookName, {
    PassageExcerpt? excerpt,
  }) {
    final curated = PassageExcerpt.forChapter(bookCode, chapterNumber);
    final sameCuratedRange = excerpt == null ||
        curated == null ||
        (curated.startVerse == excerpt.startVerse && curated.endVerse == excerpt.endVerse);

    if (sameCuratedRange) {
      for (final preset in kFeaturedChapters) {
        if (preset.bookCode.toUpperCase() == bookCode.toUpperCase() &&
            preset.chapterNumber == chapterNumber) {
          return preset.textContent;
        }
      }
    }

    final current = state.currentChapter;
    final currentText = current.textContent.trim();
    final currentMatchesChapter = current.bookCode.toUpperCase() == bookCode.toUpperCase() &&
        current.chapterNumber == chapterNumber &&
        currentText.isNotEmpty;
    if (currentMatchesChapter && !_isDifferentCuratedScripture(currentText, bookCode, chapterNumber, excerpt)) {
      return current.textContent;
    }

    if (excerpt != null) {
      final label = excerpt.displayTitle ?? excerpt.toEsvPassageQuery();
      return 'Press play to listen to $label.';
    }
    return '${BibleCanon.findBook(bookCode)?.name ?? bookName} Chapter $chapterNumber.\n\n'
        '"In the beginning was the Word, and the Word was with God, and the Word was God."';
  }

  /// True when [text] is the curated meditation for this chapter, but [excerpt]
  /// asks for a different verse range.
  bool _isDifferentCuratedScripture(
    String text,
    String bookCode,
    int chapterNumber,
    PassageExcerpt? excerpt,
  ) {
    if (excerpt == null) return false;
    final curated = PassageExcerpt.forChapter(bookCode, chapterNumber);
    if (curated == null) return false;
    if (curated.startVerse == excerpt.startVerse && curated.endVerse == excerpt.endVerse) {
      return false;
    }
    final curatedText = ref.read(offlineScriptureCacheProvider).getOfflineText(
          state.activeTranslation,
          bookCode,
          chapterNumber,
          startVerse: curated.startVerse,
          endVerse: curated.endVerse,
        );
    if (curatedText != null && curatedText.trim() == text.trim()) return true;
    for (final preset in kFeaturedChapters) {
      if (preset.bookCode.toUpperCase() == bookCode.toUpperCase() &&
          preset.chapterNumber == chapterNumber &&
          preset.textContent.trim() == text.trim()) {
        return true;
      }
    }
    return false;
  }

  Future<String> _scriptureTextFor({
    required String bookCode,
    required int chapterNumber,
    required String bookName,
    PassageExcerpt? excerpt,
  }) async {
    final fetched = await _fetchChapterText(bookCode, chapterNumber, excerpt: excerpt);
    if (fetched != null &&
        fetched.trim().isNotEmpty &&
        !_isDifferentCuratedScripture(fetched, bookCode, chapterNumber, excerpt)) {
      return fetched;
    }
    return _fallbackChapterText(bookCode, chapterNumber, bookName, excerpt: excerpt);
  }

  Future<void> routeAndPlayChapter({
    required String bookCode,
    required int chapterNumber,
    required String bookName,
    PassageExcerpt? excerpt,
    bool autoplay = true,
    bool resetIteration = true,
  }) async {
    await stopAllPlayback(reason: 'route_and_play');
    if (!ref.mounted) return;
    state = state.copyWith(readAloudPrompt: false, readAloudConfirmed: false);

    final effectiveExcerpt = excerpt ?? PassageExcerpt.forChapter(bookCode, chapterNumber);
    final fallbackText = _fallbackChapterText(
      bookCode,
      chapterNumber,
      bookName,
      excerpt: effectiveExcerpt,
    );

    if (_isEsvModeActive) {
      final rawQuery = effectiveExcerpt?.toEsvPassageQuery() ??
          (bookCode.toUpperCase() == 'VRS' ? bookName : '$bookName $chapterNumber');
      final normalizedQuery = EsvPassagePolicy.normalizePassageQuery(rawQuery);
      if (await tryPlayEsvPassage(normalizedQuery, autoplay: autoplay)) {
        if (!ref.mounted || state.activeTranslation != BibleTranslation.esv.code) return;
        state = state.copyWith(
          activeTranslation: BibleTranslation.esv.code,
          activeExcerpt: effectiveExcerpt,
        );
        return;
      }
      if (!ref.mounted || state.activeTranslation != BibleTranslation.esv.code) return;
      state = state.copyWith(
        activeTranslation: BibleTranslation.esv.code,
        audioMode: AudioMode.narrator,
        isLoading: false,
        isPlaying: false,
        clearInfoNotice: true,
        lastError: state.lastError ??
            'ESV human narrator audio for "$normalizedQuery" could not be loaded.',
      );
      return;
    }

    state = state.copyWith(
      currentChapter: ChapterInfo(
        bookCode: bookCode.toUpperCase(),
        bookName: bookName,
        chapterNumber: chapterNumber,
        audioStreamUrl: '',
        textContent: fallbackText,
        displayTitle: effectiveExcerpt?.displayTitle,
      ),
      activeExcerpt: effectiveExcerpt,
      isLoading: true,
      clearLastError: true,
      clearInfoNotice: true,
      highlightStart: 0,
      highlightEnd: 0,
    );

    final translation = state.translation;

    // Rule 0: Bundled Human Narrator Audio for open-source translations (BSB, WEB)
    // Ensures zero-network, zero-API-key human narration for curated meditation passages.
    final bundledAudioPath = BundledAudioService.getBundledAudioPath(
      translation.code,
      bookCode,
      chapterNumber,
    );
    if (bundledAudioPath != null) {
      AppLogger.info('Found bundled human narrator audio: $bundledAudioPath');
      final fetchedText = await _scriptureTextFor(
        bookCode: bookCode,
        chapterNumber: chapterNumber,
        bookName: bookName,
        excerpt: effectiveExcerpt,
      );
      if (!ref.mounted) return;

      final dynamicChapter = ChapterInfo(
        bookCode: bookCode.toUpperCase(),
        bookName: bookName,
        chapterNumber: chapterNumber,
        audioStreamUrl: bundledAudioPath,
        textContent: fetchedText,
        displayTitle: effectiveExcerpt?.displayTitle,
      );

      state = state.copyWith(
        audioMode: AudioMode.narrator,
        isOffline: true,
        clearInfoNotice: true,
      );

      await loadChapter(
        dynamicChapter,
        excerpt: effectiveExcerpt,
        autoplay: autoplay,
        resetIteration: resetIteration,
      );
      return;
    }

    // Rule 0.5: Curated excerpt or single verse without bundled audio (e.g. NIV)
    if (bookCode.toUpperCase() == 'VRS') {
      final text = state.currentChapter.textContent.isNotEmpty
          ? state.currentChapter.textContent
          : fallbackText;
      final notice = (kIsWeb && translation == BibleTranslation.niv)
          ? 'NIV audio stream is proprietary to Biblica / API.Bible. Narrating with Text-to-Speech (TTS).'
          : '${translation.fullName} (${translation.code}) excerpt narration — narrating with Text-to-Speech (TTS).';
      state = state.copyWith(
        audioMode: AudioMode.tts,
        isOffline: false,
        infoNotice: notice,
      );
      await _playTts(text, autoplay: autoplay);
      return;
    }

    // Rule 1: translation has no human narrator for this testament (e.g. WEB OT) -> TTS
    if (!translation.hasNarratorFor(bookCode)) {
      AppLogger.info(
        'Routing: ${translation.code} has no narrator for $bookCode $chapterNumber -> Using standard TTS engine.',
      );

      final chapterText = await _scriptureTextFor(
        bookCode: bookCode,
        chapterNumber: chapterNumber,
        bookName: bookName,
        excerpt: effectiveExcerpt,
      );
      if (!ref.mounted) return;

      final dynamicChapter = ChapterInfo(
        bookCode: bookCode.toUpperCase(),
        bookName: bookName,
        chapterNumber: chapterNumber,
        audioStreamUrl: '',
        textContent: chapterText,
        displayTitle: effectiveExcerpt?.displayTitle,
      );

      final testament = BibleCanon.isOldTestament(bookCode) ? 'OT' : 'NT';
      state = state.copyWith(
        currentChapter: dynamicChapter,
        audioMode: AudioMode.tts,
        isOffline: false,
        infoNotice:
            '${translation.fullName} (${translation.code}) has no $testament narrator on API.Bible — narrating with Text-to-Speech (TTS).',
      );

      await _playTts(chapterText, autoplay: autoplay);
      return;
    }

    // Rule 2: translation has a narrator for this testament (BSB OT+NT, NIV OT+NT, WEB NT)
    final bibleId = translation.audioBibleId;
    final chapterId = '${bookCode.toUpperCase()}.$chapterNumber';
    final url = '/audio-bibles/$bibleId/chapters/$chapterId';
    final activeKey = _getActiveApiKey();

    if (activeKey.isEmpty) {
      AppLogger.info(
        'API.Bible key unconfigured; gracefully routing to contemplative voice for $chapterId.',
      );
      final cachedText = await _scriptureTextFor(
        bookCode: bookCode,
        chapterNumber: chapterNumber,
        bookName: bookName,
        excerpt: effectiveExcerpt,
      );
      final noticeMessage = translation == BibleTranslation.niv
          ? 'NIV audio stream currently unavailable. Narrating with contemplative voice.'
          : 'Narrator stream unavailable — narrating ${translation.fullName} (${translation.code}) with contemplative voice.';
      state = state.copyWith(isOffline: false);
      _switchToTtsFallback(
        noticeMessage,
        overrideText: cachedText,
        autoplay: autoplay,
      );
      return;
    }

    AppLogger.info('Fetching ${translation.code} narrator stream for $chapterId ($bibleId) from API.Bible...');

    try {
      final response = await _dio.get(url);
      if (!ref.mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final String? streamUrl = data['resourceUrl'];
        _recordFumsToken(response.data, kind: 'audio', chapterId: chapterId);

        if (streamUrl != null && streamUrl.isNotEmpty) {
          final fetchedText = await _scriptureTextFor(
            bookCode: bookCode,
            chapterNumber: chapterNumber,
            bookName: bookName,
            excerpt: effectiveExcerpt,
          );
          if (!ref.mounted) return;

          final dynamicChapter = ChapterInfo(
            bookCode: bookCode.toUpperCase(),
            bookName: bookName,
            chapterNumber: chapterNumber,
            audioStreamUrl: streamUrl,
            textContent: fetchedText,
            displayTitle: effectiveExcerpt?.displayTitle,
          );

          state = state.copyWith(
            audioMode: AudioMode.narrator,
            isOffline: false,
            clearInfoNotice: true,
          );

          await loadChapter(
        dynamicChapter,
        excerpt: effectiveExcerpt,
        autoplay: autoplay,
        resetIteration: resetIteration,
      );
          return;
        }
      }
      throw Exception('Resource URL empty for $chapterId');
    } catch (e, stack) {
      if (!ref.mounted) return;
      AppLogger.error(
        'API.Bible narrator fetch failed for $chapterId',
        error: e,
        stackTrace: stack,
        properties: {
          'book_code': bookCode.toUpperCase(),
          'chapter': chapterNumber,
          'translation': translation.code,
          'audio_mode': state.audioMode.name,
          'bible_id': bibleId,
        },
      );
      final cachedText = await _scriptureTextFor(
        bookCode: bookCode,
        chapterNumber: chapterNumber,
        bookName: bookName,
        excerpt: effectiveExcerpt,
      );

      final noticeMessage = translation == BibleTranslation.niv
          ? 'NIV audio stream currently unavailable. Narrating with contemplative voice.'
          : 'Narrator stream currently unavailable — narrating ${translation.fullName} (${translation.code}) with contemplative voice.';

      state = state.copyWith(isOffline: false);
      _switchToTtsFallback(
        noticeMessage,
        overrideText: cachedText,
        autoplay: autoplay,
      );
    }
  }

  /// Licensed translations (NIV) return a `meta.fumsToken` that API.Bible's
  /// Fair Use Management System expects to be reported. We log it so usage is
  /// auditable; see niv_restrictions.md for the reporting plan.
  void _recordFumsToken(dynamic body, {required String kind, required String chapterId}) {
    if (!state.translation.isLicensed) return;
    String? token;
    if (body is Map) {
      final meta = body['meta'];
      if (meta is Map) {
        token = meta['fumsToken'] as String?;
      }
    }
    if (token == null || token.isEmpty) return;
    AppLogger.logEvent('fums_token_received', {
      'translation': state.translation.code,
      'kind': kind,
      'chapter_id': chapterId,
    });
  }

  Future<String?> _fetchChapterText(
    String bookCode,
    int chapterNumber, {
    PassageExcerpt? excerpt,
  }) async {
    final requested = excerpt ?? PassageExcerpt.forChapter(bookCode, chapterNumber);
    try {
      final cache = ref.read(offlineScriptureCacheProvider);
      final cached = requested == null
          ? cache.getOfflineText(state.activeTranslation, bookCode, chapterNumber)
          : cache.getOfflineText(
              state.activeTranslation,
              bookCode,
              chapterNumber,
              startVerse: requested.startVerse,
              endVerse: requested.endVerse,
            );
      if (cached != null &&
          cached.trim().isNotEmpty &&
          !_isDifferentCuratedScripture(cached, bookCode, chapterNumber, excerpt)) {
        return cached;
      }
    } catch (_) {}

    final activeKey = _getActiveApiKey();
    if (activeKey.isNotEmpty) {
      try {
        final textBibleId = state.translation.textBibleId;
        final passageId = requested == null
            ? '${bookCode.toUpperCase()}.$chapterNumber'
            : '${bookCode.toUpperCase()}.$chapterNumber.${requested.startVerse}-${bookCode.toUpperCase()}.$chapterNumber.${requested.endVerse}';
        final res = await _dio.get(
          '/bibles/$textBibleId/passages/$passageId',
          queryParameters: {'content-type': 'text', 'include-verse-numbers': 'false'},
        );
        if (res.statusCode == 200 && res.data != null) {
          _recordFumsToken(res.data, kind: 'text', chapterId: passageId);
          final content = res.data['data']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            final cleaned = content.replaceAll(RegExp(r'\s+'), ' ').trim();
            if (requested == null) {
              try {
                ref.read(offlineScriptureCacheProvider).saveOfflineToDisk(
                  state.activeTranslation,
                  bookCode,
                  chapterNumber,
                  cleaned,
                );
              } catch (_) {}
            }
            return cleaned;
          }
        }
      } catch (_) {}
    }

    if (requested != null &&
        (state.activeTranslation == 'BSB' || state.activeTranslation == 'WEB')) {
      final ranged = await ref.read(publicDomainPassageTextProvider).fetchRange(
        translation: state.activeTranslation,
        bookCode: bookCode,
        chapterNumber: chapterNumber,
        startVerse: requested.startVerse,
        endVerse: requested.endVerse,
      );
      if (ranged != null &&
          ranged.trim().isNotEmpty &&
          !_isDifferentCuratedScripture(ranged, bookCode, chapterNumber, excerpt)) {
        return ranged;
      }
    }
    return null;
  }

  /// The range that [query] names, so a later translation change does not
  /// keep whatever excerpt was on screen before this ESV search.
  PassageExcerpt? _excerptForPlayedQuery(String query) {
    final parsed = PassageShareLink.tryParse(query);
    if (parsed == null) return null;
    if (parsed.startVerse == null) {
      return PassageExcerpt.forChapter(parsed.book.code, parsed.chapter);
    }
    return PassageExcerpt.customExcerpt(
      bookCode: parsed.book.code,
      chapterNumber: parsed.chapter,
      startVerse: parsed.startVerse!,
      endVerse: parsed.endVerse ?? parsed.startVerse!,
      displayTitle: parsed.canonical,
    );
  }

  /// Plays [query] from the ESV API, one HTTP call per verse in a range.
  ///
  /// Returns false when the key is unset or the request fails, without
  /// replacing a later narrator or bible-api.com attempt.
  Future<bool> tryPlayEsvPassage(String query, {bool autoplay = true}) async {
    final esv = ref.read(esvApiClientProvider);
    if (!esv.isConfigured) return false;

    await stopAllPlayback(reason: 'play_esv');
    if (!ref.mounted) return false;
    state = state.copyWith(
      isLoading: true,
      clearLastError: true,
      clearInfoNotice: true,
      audioMode: AudioMode.narrator,
      activeTranslation: BibleTranslation.esv.code,
      highlightStart: 0,
      highlightEnd: 0,
    );

    try {
      final verses = await esv.fetchVerseByVerse(query);
      if (!ref.mounted) return false;
      if (state.activeTranslation != BibleTranslation.esv.code) return true;
      if (verses.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          audioMode: AudioMode.narrator,
          clearInfoNotice: true,
          lastError: 'ESV passage "$query" could not be found.',
        );
        return false;
      }

      final verseStr = '${verses.map((verse) => verse.text).join(' ')} $kEsvShortCopyright';
      final joinedRef = EsvApiClient.joinedReference(verses);
      final playedExcerpt = _excerptForPlayedQuery(query);
      if (!ref.mounted) return false;
      if (state.activeTranslation != BibleTranslation.esv.code) return true;
      // Replace the passage as soon as the verses arrive. Waiting for the
      // player to finish loading left the previous excerpt in place, so a
      // translation change during that gap replayed the old range.
      state = state.copyWith(
        currentChapter: ChapterInfo(
          bookCode: 'VRS',
          bookName: joinedRef,
          chapterNumber: 1,
          displayTitle: joinedRef,
          audioStreamUrl: '',
          textContent: verseStr,
        ),
        activeExcerpt: playedExcerpt,
        clearActiveExcerpt: playedExcerpt == null,
      );

      final directAudioUrl = await esv.resolvePassageAudioUrl(query) ??
          EsvApiClient.directHwAudioUrl(query);
      try {
        final mediaItem = MediaItem(
          id: directAudioUrl,
          album: 'Selah Scripture Audio',
          title: joinedRef,
          artist: 'David Cochran Heath (ESV)',
          artUri: Uri.parse('https://selahword.web.app/icons/Icon-192.png'),
        );
        final needsAuthHeader = directAudioUrl.contains('api.esv.org') && !kIsWeb;
        final source = AudioSource.uri(
          Uri.parse(directAudioUrl),
          headers: needsAuthHeader ? {'Authorization': 'Token ${esv.apiKey}'} : null,
          tag: mediaItem,
        );
        final dur = await _audioPlayer.setAudioSource(source);
        if (!ref.mounted) return false;
        if (state.activeTranslation != BibleTranslation.esv.code) return true;
        _recordListeningStart();
        state = state.copyWith(
          isLoading: false,
          isPlaying: autoplay,
          audioMode: AudioMode.narrator,
          activeTranslation: BibleTranslation.esv.code,
          duration: dur ?? Duration.zero,
          position: Duration.zero,
          currentChapter: ChapterInfo(
            bookCode: 'VRS',
            bookName: joinedRef,
            chapterNumber: 1,
            displayTitle: joinedRef,
            audioStreamUrl: directAudioUrl,
            textContent: verseStr,
          ),
          activeExcerpt: playedExcerpt,
          clearActiveExcerpt: playedExcerpt == null,
          clearInfoNotice: true,
          clearLastError: true,
        );
        if (autoplay) {
          _audioPlayer.play();
        }
        return true;
      } catch (audioErr) {
        AppLogger.error('ESV human audio playback failed: $audioErr');
        if (!ref.mounted) return false;
        if (state.activeTranslation != BibleTranslation.esv.code) return true;
        if (state.readAloudConfirmed) {
          state = state.copyWith(
            currentChapter: state.currentChapter.copyWith(
              textContent: verseStr,
              displayTitle: joinedRef,
              audioStreamUrl: '',
            ),
            isLoading: false,
            isPlaying: false,
            clearLastError: true,
          );
          await _playTts(verseStr, autoplay: autoplay, confirmed: true);
          return true;
        }
        state = state.copyWith(
          currentChapter: state.currentChapter.copyWith(
            textContent: verseStr,
            displayTitle: joinedRef,
            audioStreamUrl: '',
          ),
          isLoading: false,
          isPlaying: false,
          audioMode: AudioMode.narrator,
          readAloudPrompt: false,
          clearInfoNotice: true,
          lastError: 'ESV human narrator audio for "$query" could not be played.',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('ESV verse fetch failed', error: e);
      if (ref.mounted && state.activeTranslation == BibleTranslation.esv.code) {
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          audioMode: AudioMode.narrator,
          clearInfoNotice: true,
          lastError: 'ESV passage "$query" could not be loaded. Please check your connection.',
        );
        return false;
      }
      return ref.mounted;
    }
  }

  Future<void> fetchAndPlaySingleVerse(
    String query, {
    bool tryEsv = true,
    bool autoplay = true,
  }) async {
    if ((tryEsv || _isEsvModeActive) &&
        await tryPlayEsvPassage(query, autoplay: autoplay)) {
      return;
    }

    if (_isEsvModeActive) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        audioMode: AudioMode.narrator,
        clearInfoNotice: true,
        lastError: state.lastError ?? 'ESV passage "$query" could not be played.',
      );
      return;
    }

    await stopAllPlayback();
    if (!ref.mounted) return;

    state = state.copyWith(
      isLoading: true,
      clearLastError: true,
      clearInfoNotice: true,
      audioMode: AudioMode.tts,
      highlightStart: 0,
      highlightEnd: 0,
    );

    try {
      final res = await Dio().get('https://bible-api.com/${Uri.encodeComponent(query.trim())}');
      if (res.statusCode == 200 && res.data is Map && res.data['text'] != null) {
        final refStr = res.data['reference'] ?? query;
        final verseStr = (res.data['text'] as String).replaceAll('\n', ' ').trim();

        final verseChapter = ChapterInfo(
          bookCode: 'VRS',
          bookName: refStr,
          chapterNumber: 1,
          audioStreamUrl: '',
          textContent: verseStr,
        );

        state = state.copyWith(
          currentChapter: verseChapter,
          infoNotice:
              'Single verse loaded — narrating with word-synchronized karaoke highlighting.',
        );

        await _playTts(verseStr, autoplay: autoplay);
        return;
      }
    } catch (e) {
      AppLogger.error('Single verse fetch failed', error: e);
    }

    _switchToTtsFallback(
      'Could not load online verse. Narrating fallback meditation verse.',
      autoplay: autoplay,
    );
  }

  Future<void> stopAllPlayback({String reason = 'user_action'}) async {
    _gapTimer?.cancel();
    final secondsListened = _pauseSecondsListened();
    if (state.isPlaying) {
      AppLogger.logEvent('playback_stopped', {
        'passage': state.currentChapter.reference,
        'translation': state.activeTranslation,
        'current_iteration': state.currentIteration,
        'seconds_listened': secondsListened,
        'reason': reason,
      });
    }
    _resetSessionSeconds();
    try {
      await _flutterTts.stop();
    } catch (_) {}
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (!ref.mounted) return;
    state = state.copyWith(isPlaying: false, isPausedInGap: false);
  }

  /// Removes trailing copyright notices (e.g. `(ESV)`) from text spoken by TTS.
  /// The mark is displayed visually in textContent but not spoken aloud.
  static String _spokenText(String text) {
    const suffix = ' $kEsvShortCopyright';
    return text.endsWith(suffix) ? text.substring(0, text.length - suffix.length) : text;
  }

  Future<void> _playTts(String text, {bool autoplay = true, bool confirmed = false}) async {
    await stopAllPlayback(reason: 'play_tts');
    if (!ref.mounted) return;

    final allowed = confirmed || state.readAloudConfirmed;
    if (_isEsvModeActive && !allowed) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        audioMode: AudioMode.narrator,
        readAloudPrompt: false,
        clearInfoNotice: true,
        lastError: state.lastError ?? 'ESV human narrator audio unavailable.',
      );
      return;
    }
    if (!allowed) {
      _offerReadAloud(text);
      return;
    }

    final spoken = _spokenText(text);
    _recordListeningStart();
    state = state.copyWith(
      isLoading: false,
      isPlaying: autoplay,
      isPausedInGap: false,
      audioMode: AudioMode.tts,
      readAloudPrompt: false,
      readAloudConfirmed: true,
      isOffline: false,
      duration: Duration(seconds: (spoken.split(' ').length * 0.45).ceil()),
      position: Duration.zero,
    );

    if (!autoplay) return;

    AppLogger.logEvent('play_tts', {
      'chapter': state.currentChapter.reference,
      'translation': state.activeTranslation,
    });

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(spoken);
    } catch (e) {
      AppLogger.error('TTS speech failed', error: e);
      state = state.copyWith(isPlaying: false, lastError: 'TTS playback error: $e');
    }
  }

  void _offerReadAloud(String text) {
    if (!ref.mounted) return;
    final label = state.currentChapter.displayTitle ?? state.currentChapter.reference;
    final words = text.trim();
    state = state.copyWith(
      isLoading: false,
      isPlaying: false,
      audioMode: AudioMode.narrator,
      hasTimestamps: false,
      readAloudPrompt: true,
      readAloudConfirmed: false,
      currentChapter: state.currentChapter.copyWith(
        audioStreamUrl: '',
        textContent: words.isEmpty ? state.currentChapter.textContent : words,
      ),
      infoNotice:
          'Verse timing for $label is not aligned, so Selah did not start a synthetic voice or a different passage.',
      clearLastError: true,
    );
  }

  /// Speaks the words already on screen. No-op unless the listener just agreed.
  Future<void> confirmReadAloud() async {
    if (!ref.mounted) return;
    state = state.copyWith(readAloudPrompt: false, readAloudConfirmed: true);
    await _playTts(state.currentChapter.textContent, confirmed: true);
  }

  /// Leaves the words on screen and does not speak.
  void declineReadAloud() {
    if (!ref.mounted) return;
    final label = state.currentChapter.displayTitle ?? state.currentChapter.reference;
    state = state.copyWith(
      readAloudPrompt: false,
      readAloudConfirmed: false,
      isPlaying: false,
      isLoading: false,
      audioMode: AudioMode.narrator,
      infoNotice:
          'Verse timing for $label is not aligned, so Selah did not start a synthetic voice or a different passage.',
    );
  }

  void _switchToTtsFallback(String notice, {String? overrideText, bool autoplay = true}) {
    if (!ref.mounted) return;
    final text = overrideText ?? state.currentChapter.textContent;
    if (_isEsvModeActive && !state.readAloudConfirmed) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        audioMode: AudioMode.narrator,
        readAloudPrompt: false,
        clearInfoNotice: true,
        lastError: state.lastError ?? 'ESV human narrator audio unavailable.',
      );
      return;
    }
    if (!state.readAloudConfirmed) {
      state = state.copyWith(
        isLoading: false,
        currentChapter: state.currentChapter.copyWith(textContent: text),
        infoNotice: notice,
      );
      _offerReadAloud(text);
      return;
    }
    state = state.copyWith(
      isLoading: false,
      audioMode: AudioMode.tts,
      infoNotice: notice,
      currentChapter: state.currentChapter.copyWith(textContent: text),
    );
    _playTts(text, autoplay: autoplay, confirmed: true);
  }

  Future<void> loadChapter(
    ChapterInfo chapter, {
    PassageExcerpt? excerpt,
    bool autoplay = true,
    bool resetIteration = true,
  }) async {
    await stopAllPlayback(reason: 'load_chapter');
    if (!ref.mounted) return;

    if (_isEsvModeActive) {
      final fallbackQuery = chapter.bookCode.toUpperCase() == 'VRS'
          ? chapter.bookName
          : '${chapter.bookName} ${chapter.chapterNumber}';
      final query = esvPassageQueryFor(chapter, excerpt: excerpt) ??
          EsvPassagePolicy.normalizePassageQuery(fallbackQuery);
      await tryPlayEsvPassage(query, autoplay: autoplay);
      return;
    }

    _currentTimestamps = await TimestampLoaderService.loadChapterTimestamps(
      translation: state.activeTranslation,
      bookCode: chapter.bookCode,
      chapterNumber: chapter.chapterNumber,
    );
    final hasTimestamps = _currentTimestamps != null && _currentTimestamps!.isNotEmpty;
    if (hasTimestamps) {
      AppLogger.info(
        'WhisperX timestamps loaded for ${chapter.reference}: ${_currentTimestamps!.length} verses.',
      );
    }

    final effectiveExcerpt = excerpt ?? PassageExcerpt.forChapter(
      chapter.bookCode,
      chapter.chapterNumber,
    );

    final window = effectiveExcerpt?.clipWindow(_currentTimestamps);
    _clipOffset = window?.start ?? Duration.zero;
    final curated = PassageExcerpt.forChapter(chapter.bookCode, chapter.chapterNumber);
    final decision = decidePassageAudio(
      PassageAudioSituation(
        esvMode: false,
        translationHasNarrator: state.translation.hasNarratorFor(chapter.bookCode),
        hasBundledChapterAudio: chapter.audioStreamUrl.startsWith('assets/'),
        hasChapterStream:
            chapter.audioStreamUrl.isNotEmpty && !chapter.audioStreamUrl.startsWith('assets/'),
        requestedStart: effectiveExcerpt?.startVerse,
        requestedEnd: effectiveExcerpt?.endVerse,
        curatedStart: curated?.startVerse,
        curatedEnd: curated?.endVerse,
        clipCoversRequestedRange: window != null,
        readAloudConfirmed: state.readAloudConfirmed,
      ),
    );
    final refuseUnclipped = decision == PassageAudioDecision.holdUnaligned ||
        decision == PassageAudioDecision.askBeforeReadAloud ||
        decision == PassageAudioDecision.speakWithTts ||
        (decision == PassageAudioDecision.playNarratorClip && window == null);
    if (chapter.audioStreamUrl.isNotEmpty && refuseUnclipped) {
      final label =
          effectiveExcerpt?.displayTitle ?? chapter.displayTitle ?? chapter.reference;
      AppLogger.logEvent('custom_passage_unaligned', {
        'passage': label,
        'translation': state.activeTranslation,
        'tts': decision == PassageAudioDecision.speakWithTts,
      });
      final words = chapter.textContent.trim();
      final canShowRange = words.isNotEmpty && !words.startsWith('Press play to listen');
      final shown = canShowRange ? chapter.textContent : 'Press play to listen to $label.';
      state = state.copyWith(
        currentChapter: chapter.copyWith(
          audioStreamUrl: '',
          displayTitle: chapter.displayTitle ?? label,
          textContent: shown,
        ),
        audioMode: AudioMode.narrator,
        hasTimestamps: false,
        activeExcerpt: effectiveExcerpt,
        isLoading: false,
        isPlaying: false,
        isOffline: false,
        infoNotice: canShowRange
            ? 'Verse timing for $label is not aligned, so Selah did not start a synthetic voice or a different passage.'
            : 'Verse timing for $label is not aligned, and those words are not loaded. Selah will not play a different passage.',
        clearLastError: true,
      );
      if (canShowRange && decision == PassageAudioDecision.speakWithTts) {
        await _playTts(shown, autoplay: autoplay, confirmed: true);
      } else if (canShowRange && decision == PassageAudioDecision.askBeforeReadAloud) {
        _offerReadAloud(shown);
      }
      return;
    }

    state = state.copyWith(
      currentChapter: chapter,
      audioMode: AudioMode.narrator,
      hasTimestamps: hasTimestamps,
      activeExcerpt: effectiveExcerpt,
      isLoading: true,
      isPlaying: false,
      isPausedInGap: false,
      currentIteration: resetIteration ? 1 : state.currentIteration,
      position: Duration.zero,
      duration: Duration.zero,
      clearLastError: true,
    );

    AppLogger.logEvent('play_chapter', {
      'translation': state.activeTranslation,
      'book': chapter.bookCode,
      'chapter': chapter.chapterNumber,
      'audio_url': chapter.audioStreamUrl,
      'has_timestamps': hasTimestamps,
      'has_excerpt': effectiveExcerpt != null,
    });

    if (chapter.audioStreamUrl.isEmpty) {
      await routeAndPlayChapter(
        bookCode: chapter.bookCode,
        chapterNumber: chapter.chapterNumber,
        bookName: chapter.bookName,
        excerpt: effectiveExcerpt,
        autoplay: autoplay,
        resetIteration: resetIteration,
      );
      return;
    }

    try {
      final isAsset = chapter.audioStreamUrl.startsWith('assets/');
      final mediaItem = MediaItem(
        id: chapter.audioStreamUrl,
        album: 'Selah Scripture Audio',
        title: chapter.displayTitle ?? chapter.reference,
        artist: 'Human Narrator (${state.activeTranslation})',
        artUri: Uri.parse('https://selahword.web.app/icons/Icon-192.png'),
      );
      final esvClient = ref.read(esvApiClientProvider);
      final isEsvAudio = chapter.audioStreamUrl.contains('api.esv.org') && !kIsWeb;
      final audioHeaders = isEsvAudio && esvClient.isConfigured
          ? {'Authorization': 'Token ${esvClient.apiKey}'}
          : null;
      final UriAudioSource baseSource = isAsset
          ? AudioSource.asset(chapter.audioStreamUrl, tag: mediaItem)
          : AudioSource.uri(
              Uri.parse(chapter.audioStreamUrl),
              headers: audioHeaders,
              tag: mediaItem,
            );

      final AudioSource finalSource = window == null
          ? baseSource
          : ClippingAudioSource(
              child: baseSource,
              start: window.start,
              end: window.end,
              tag: mediaItem,
            );

      final dur = await _audioPlayer.setAudioSource(finalSource);
      if (window != null) {
        AppLogger.info(
          'Clipped ${chapter.reference} to excerpt ${window.start.inMilliseconds}–${window.end.inMilliseconds}ms with MediaItem notification tag',
        );
      }
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        duration: dur ?? Duration.zero,
        isOffline: isAsset,
      );
      if (autoplay) {
        play();
      }
    } catch (e, stack) {
      if (!ref.mounted) return;
      AppLogger.error(
        'Failed to set audio source in player',
        error: e,
        stackTrace: stack,
        properties: {
          'book_code': chapter.bookCode,
          'chapter': chapter.chapterNumber,
          'translation': state.activeTranslation,
          'audio_mode': state.audioMode.name,
        },
      );
      state = state.copyWith(isOffline: false);
      _switchToTtsFallback(
        'Audio stream blocked or failed. Switched to Text-to-Speech (TTS).',
        autoplay: autoplay,
      );
    }
  }

  void togglePlayPause() {
    if (state.currentChapter.bookCode.isEmpty) return;
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  static String _normalizedReference(String raw) => raw
      .replaceAll(RegExp(r'[–—−]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();

  /// Lands on a shared reference without asking the recipient to sign in.
  /// Playback stays ready on the play control; opening a link does not autoplay.
  void presentSharedPassage(SharedPassage passage) {
    ChapterInfo? preset;
    final sharedTitle = _normalizedReference(passage.canonical);
    for (final chapter in kFeaturedChapters) {
      final featuredTitle = _normalizedReference(chapter.displayTitle ?? chapter.reference);
      if (featuredTitle == sharedTitle) {
        preset = chapter;
        break;
      }
    }

    PassageExcerpt? excerpt;
    if (passage.startVerse != null) {
      excerpt = PassageExcerpt.customExcerpt(
        bookCode: passage.book.code,
        chapterNumber: passage.chapter,
        startVerse: passage.startVerse!,
        endVerse: passage.endVerse ?? passage.startVerse!,
        displayTitle: passage.canonical,
      );
    } else {
      excerpt = PassageExcerpt.forChapter(passage.book.code, passage.chapter);
    }

    state = state.copyWith(
      currentChapter: ChapterInfo(
        bookCode: passage.book.code,
        bookName: passage.book.name,
        chapterNumber: passage.chapter,
        audioStreamUrl: '',
        textContent: preset?.textContent ?? 'Press play to listen to ${passage.canonical}.',
        displayTitle: passage.canonical,
      ),
      activeExcerpt: excerpt,
      clearActiveExcerpt: excerpt == null,
      isPlaying: false,
      isLoading: false,
      clearLastError: true,
      clearInfoNotice: true,
      readAloudPrompt: false,
      readAloudConfirmed: false,
      audioMode: AudioMode.narrator,
    );
  }

  /// Keeps the player on screen and explains that the link is not a passage.
  void rejectSharedReference(String raw) {
    final message = PassageShareLink.friendlyError(raw);
    state = state.copyWith(
      currentChapter: ChapterInfo(
        bookCode: '',
        bookName: 'Selah',
        chapterNumber: 1,
        audioStreamUrl: '',
        textContent: 'This link does not open a passage. Search for another reference, or ask for a new link.',
        displayTitle: 'Passage link',
      ),
      isPlaying: false,
      isLoading: false,
      clearActiveExcerpt: true,
      clearInfoNotice: true,
      lastError: message,
    );
  }

  Future<void> play() async {
    if (state.currentChapter.bookCode.isEmpty) return;
    _recordListeningStart();
    if (state.isPausedInGap) {
      _gapTimer?.cancel();
      state = state.copyWith(isPausedInGap: false, isPlaying: true);
      if (state.audioMode == AudioMode.narrator || _isEsvModeActive) {
        _audioPlayer.play();
      } else {
        _flutterTts.speak(_spokenText(state.currentChapter.textContent));
      }
      return;
    }

    if ((state.audioMode == AudioMode.narrator || _isEsvModeActive) &&
        state.currentChapter.audioStreamUrl.isEmpty) {
      // Show that playback has started before audio plugins respond.
      state = state.copyWith(isLoading: true, clearLastError: true);
      await routeAndPlayChapter(
        bookCode: state.currentChapter.bookCode,
        chapterNumber: state.currentChapter.chapterNumber,
        bookName: state.currentChapter.bookName,
        excerpt: state.activeExcerpt,
      );
      return;
    }

    state = state.copyWith(isPlaying: true, clearLastError: true);

    if (state.audioMode == AudioMode.tts && !_isEsvModeActive) {
      await _flutterTts.speak(_spokenText(state.currentChapter.textContent));
      return;
    }

    final isCompleted = _audioPlayer.processingState == ProcessingState.completed;
    final isAtEnd = state.duration > Duration.zero && state.position >= state.duration;

    if (isCompleted || isAtEnd) {
      if (state.currentChapter.audioStreamUrl.isNotEmpty) {
        final directAudioUrl = state.currentChapter.audioStreamUrl;
        final needsAuthHeader = directAudioUrl.contains('api.esv.org') && !kIsWeb;
        final esv = ref.read(esvApiClientProvider);
        final mediaItem = MediaItem(
          id: directAudioUrl,
          album: 'Selah Scripture Audio',
          title: state.currentChapter.displayTitle ?? state.currentChapter.bookName,
          artist: 'David Cochran Heath (ESV)',
          artUri: Uri.parse('https://selahword.web.app/icons/Icon-192.png'),
        );
        final source = AudioSource.uri(
          Uri.parse(directAudioUrl),
          headers: needsAuthHeader ? {'Authorization': 'Token ${esv.apiKey}'} : null,
          tag: mediaItem,
        );
        await _audioPlayer.setAudioSource(source);
      } else {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.setVolume(1.0);
    }

    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
    } catch (e, stack) {
      AppLogger.error(
        'Playback trigger failed',
        error: e,
        stackTrace: stack,
        properties: {
          'book_code': state.currentChapter.bookCode,
          'chapter': state.currentChapter.chapterNumber,
          'translation': state.activeTranslation,
          'audio_mode': state.audioMode.name,
        },
      );
      if (_isEsvModeActive) {
        state = state.copyWith(
          isPlaying: false,
          audioMode: AudioMode.narrator,
          clearInfoNotice: true,
          lastError: 'ESV human narrator playback failed: $e',
        );
      } else {
        _switchToTtsFallback('Playback failed. Switched to Text-to-Speech (TTS).');
      }
    }
  }

  Future<void> pause({String reason = 'user_pause'}) async {
    _gapTimer?.cancel();
    final secondsListened = _pauseSecondsListened();
    if (state.isPlaying) {
      AppLogger.logEvent('playback_stopped', {
        'passage': state.currentChapter.reference,
        'translation': state.activeTranslation,
        'current_iteration': state.currentIteration,
        'seconds_listened': secondsListened,
        'reason': reason,
      });
    }
    if (state.audioMode == AudioMode.narrator) {
      await _audioPlayer.pause();
    } else {
      await _flutterTts.stop();
    }
    state = state.copyWith(isPlaying: false, isPausedInGap: false);
  }

  void seek(Duration pos) {
    if (state.audioMode == AudioMode.narrator) {
      _audioPlayer.seek(pos);
    }
  }

  void setRepetitions(int reps) {
    state = state.copyWith(repetitions: reps);
    AppLogger.logEvent('change_setting', {'setting': 'repetitions', 'value': reps});
  }

  void cycleRepetitions() {
    const repsList = [1, 3, 7, -1];
    final currentIdx = repsList.indexOf(state.repetitions);
    final nextReps = repsList[(currentIdx + 1) % repsList.length];
    setRepetitions(nextReps);
  }

  void setPauseGap(int seconds) {
    state = state.copyWith(pauseGapSeconds: seconds);
    AppLogger.logEvent('change_setting', {'setting': 'pauseGapSeconds', 'value': seconds});
  }

  void setTranslation(String translation, {bool force = false, bool resetIteration = true}) {
    final target = BibleTranslation.fromCode(translation);
    final policy = ref.read(esvPassagePolicyProvider);
    if (!force && !policy.showApiBibleTranslations && target.code != BibleTranslation.esv.code) {
      return;
    }

    final shouldClearShuffle =
        !policy.showApiBibleTranslations || target.code == BibleTranslation.esv.code;

    if (state.activeTranslation == target.code) {
      if (shouldClearShuffle && state.shuffleTranslations) {
        state = state.copyWith(shuffleTranslations: false);
      }
      return;
    }

    final previousTranslation = state.activeTranslation;
    state = state.copyWith(
      activeTranslation: target.code,
      shuffleTranslations: shouldClearShuffle ? false : state.shuffleTranslations,
    );

    // Persist via SharedPreferences / LocalStorage for next launch
    try {
      ref.read(userPreferencesProvider).setLastTranslationCode(target.code);
    } catch (_) {}

    AppLogger.logEvent('change_translation', {
      'translation': target.code,
      'translation_name': target.fullName,
      'previous_translation': previousTranslation,
      'is_licensed': target.isLicensed,
      'chapter': state.currentChapter.reference,
    });

    // A broken link has no chapter. Keep the friendly error on screen.
    if (state.currentChapter.bookCode.isEmpty) return;

    // ESV playback stores a synthetic VRS chapter. Route the real book so a
    // switch to BSB or WEB does not keep the ESV wording under the new label.
    if (state.currentChapter.bookCode.toUpperCase() == 'VRS') {
      final excerpt = state.activeExcerpt;
      if (excerpt != null && excerpt.bookCode.toUpperCase() != 'VRS') {
        final book = BibleCanon.findBook(excerpt.bookCode);
        routeAndPlayChapter(
          bookCode: excerpt.bookCode,
          chapterNumber: excerpt.chapterNumber,
          bookName: book?.name ?? state.currentChapter.bookName,
          excerpt: excerpt,
          resetIteration: resetIteration,
        );
        return;
      }
      final parsed = PassageShareLink.tryParse(
        state.currentChapter.displayTitle ?? state.currentChapter.bookName,
      );
      if (parsed != null) {
        final recovered = parsed.startVerse == null
            ? null
            : PassageExcerpt.customExcerpt(
                bookCode: parsed.book.code,
                chapterNumber: parsed.chapter,
                startVerse: parsed.startVerse!,
                endVerse: parsed.endVerse ?? parsed.startVerse!,
                displayTitle: parsed.canonical,
              );
        routeAndPlayChapter(
          bookCode: parsed.book.code,
          chapterNumber: parsed.chapter,
          bookName: parsed.book.name,
          excerpt: recovered,
          resetIteration: resetIteration,
        );
        return;
      }
    }

    // Keep a shared or custom range. Dropping the excerpt here would turn
    // John 16:32-33 into the whole of John 16 when the listener changes translation.
    final excerpt = state.activeExcerpt;
    final excerptMatchesChapter = excerpt != null &&
        excerpt.bookCode.toUpperCase() == state.currentChapter.bookCode.toUpperCase() &&
        excerpt.chapterNumber == state.currentChapter.chapterNumber;
    routeAndPlayChapter(
      bookCode: state.currentChapter.bookCode,
      chapterNumber: state.currentChapter.chapterNumber,
      bookName: state.currentChapter.bookName,
      excerpt: excerptMatchesChapter ? excerpt : null,
      resetIteration: resetIteration,
    );
  }

  void toggleKaraoke(bool enabled) {
    state = state.copyWith(karaokeEnabled: enabled);
    AppLogger.logEvent('toggle_karaoke', {'enabled': enabled});
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    _volumeFadeTimer?.cancel();

    if (minutes == null || minutes <= 0) {
      _audioPlayer.setVolume(1.0).catchError((_) => {});
      state = state.copyWith(clearSleepTimer: true);
      AppLogger.info('Sleep timer cancelled.');
      AppLogger.logEvent('sleep_timer_cancelled', {});
      return;
    }

    final endTime = DateTime.now().add(Duration(minutes: minutes));
    state = state.copyWith(
      sleepTimerMinutes: minutes,
      sleepTimerEndTime: endTime,
    );

    AppLogger.info('Sleep timer set for $minutes minutes (ending at $endTime).');
    AppLogger.logEvent('sleep_timer_set', {'minutes': minutes});

    // Schedule 30s gentle volume fade before timer ends
    final fadeStartDelay = Duration(minutes: minutes) - const Duration(seconds: 30);
    if (fadeStartDelay > Duration.zero) {
      _volumeFadeTimer = Timer(fadeStartDelay, _startSleepVolumeFade);
    } else {
      _startSleepVolumeFade();
    }

    _sleepTimer = Timer(Duration(minutes: minutes), _onSleepTimerExpired);
  }

  void _startSleepVolumeFade() {
    AppLogger.info('Sleep timer: Starting gentle 30s volume fade-out.');
    int step = 0;
    const totalSteps = 30;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      step++;
      final volume = (1.0 - (step / totalSteps)).clamp(0.0, 1.0);
      _audioPlayer.setVolume(volume).catchError((_) => {});
      if (step >= totalSteps || !state.isSleepTimerActive) {
        timer.cancel();
      }
    });
  }

  void _onSleepTimerExpired() {
    AppLogger.info('Sleep timer expired. Pausing peaceful playback.');
    AppLogger.logEvent('sleep_timer_completed', {
      'minutes': state.sleepTimerMinutes,
    });
    pause(reason: 'sleep_timer');
    _audioPlayer.setVolume(1.0).catchError((_) => {});
    state = state.copyWith(clearSleepTimer: true);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.0);
    state = state.copyWith(playbackSpeed: clamped);
    try {
      await _audioPlayer.setSpeed(clamped);
      AppLogger.info('Playback speed set to ${clamped}x');
      AppLogger.logEvent('change_playback_speed', {'speed': clamped});
    } catch (e) {
      AppLogger.info('Notice setting player speed: $e');
    }
  }

  Future<void> _handleChapterPlaybackComplete() async {
    final secondsListened = _computeAndResetSecondsListened();
    AppLogger.logEvent('playback_cycle_completed', {
      'passage': state.currentChapter.reference,
      'translation': state.activeTranslation,
      'iteration': state.currentIteration,
      'total_repetitions': state.repetitions,
      'seconds_listened': secondsListened,
    });

    // 1. Tactile loop haptic feedback (subtle light pulse signaling loop wrap)
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}

    // 2. Audio crossfade hygiene: smooth 150ms fade-out before silence gap to eliminate clicks
    if (state.audioMode == AudioMode.narrator) {
      try {
        await _audioPlayer.setVolume(0.0);
      } catch (_) {}
    }

    AppLogger.logEvent('playback_cycle_completed', {
      'reference': state.currentChapter.reference,
      'iteration': state.currentIteration,
      'target_repetitions': state.repetitions,
      'translation': state.activeTranslation,
      'audio_mode': state.audioMode.name,
    });

    if (state.repetitions != -1 && state.currentIteration >= state.repetitions) {
      final sessionTotal = _resetSessionSeconds();
      AppLogger.info('Completed all ${state.repetitions} repetitions.');
      AppLogger.logEvent('playback_completed', {
        'passage': state.currentChapter.reference,
        'translation': state.activeTranslation,
        'repetitions_completed': state.repetitions,
        'total_seconds_listened': sessionTotal,
      });
      state = state.copyWith(
        isPlaying: false,
        currentIteration: 1,
        highlightStart: 0,
        highlightEnd: 0,
      );
      if (state.audioMode == AudioMode.narrator || _isEsvModeActive) {
        _audioPlayer.pause().then((_) async {
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.setVolume(1.0);
        });
      } else {
        _audioPlayer.seek(Duration.zero);
      }
      return;
    }

    state = state.copyWith(isPausedInGap: true, highlightStart: 0, highlightEnd: 0);
    AppLogger.info('Entering silent reflection gap (${state.pauseGapSeconds}s)...');

    _gapTimer?.cancel();
    if (state.pauseGapSeconds == 0) {
      _startNextIteration();
    } else {
      _gapTimer = Timer(Duration(seconds: state.pauseGapSeconds), () {
        if (state.isPlaying || state.isPausedInGap) {
          _startNextIteration();
        }
      });
    }
  }

  void toggleShuffleTranslations() {
    if (!ref.read(esvPassagePolicyProvider).showApiBibleTranslations) {
      if (state.shuffleTranslations) {
        state = state.copyWith(shuffleTranslations: false);
      }
      return;
    }
    final next = !state.shuffleTranslations;
    state = state.copyWith(shuffleTranslations: next);
    AppLogger.logEvent('toggle_shuffle_translations', {'enabled': next});
    if (next) {
      cycleNextTranslation();
    }
  }

  void cycleNextTranslation({bool resetIteration = true}) {
    if (!ref.read(esvPassagePolicyProvider).showApiBibleTranslations) return;
    const list = ['BSB', 'WEB', 'NIV'];
    final idx = list.indexOf(state.activeTranslation);
    final next = list[(idx + 1) % list.length];
    setTranslation(next, resetIteration: resetIteration);
  }

  Future<void> _startNextIteration() async {
    _recordListeningStart();
    final nextIteration = state.currentIteration + 1;
    final repLabel = state.repetitions == -1 ? '∞' : '${state.repetitions}';
    AppLogger.info('Starting repetition $nextIteration (loop $nextIteration of $repLabel)');
    state = state.copyWith(
      currentIteration: nextIteration,
      isPausedInGap: false,
      isPlaying: true,
    );

    if (state.shuffleTranslations && ref.read(esvPassagePolicyProvider).showApiBibleTranslations) {
      cycleNextTranslation(resetIteration: false);
      return;
    }

    if (state.audioMode == AudioMode.narrator || _isEsvModeActive) {
      try {
        AppLogger.info('Resetting narrator audio source for loop $nextIteration of $repLabel');
        if (state.currentChapter.audioStreamUrl.isNotEmpty) {
          final directAudioUrl = state.currentChapter.audioStreamUrl;
          final needsAuthHeader = directAudioUrl.contains('api.esv.org') && !kIsWeb;
          final esv = ref.read(esvApiClientProvider);
          final mediaItem = MediaItem(
            id: directAudioUrl,
            album: 'Selah Scripture Audio',
            title: state.currentChapter.displayTitle ?? state.currentChapter.bookName,
            artist: 'David Cochran Heath (ESV)',
            artUri: Uri.parse('https://selahword.web.app/icons/Icon-192.png'),
          );
          final source = AudioSource.uri(
            Uri.parse(directAudioUrl),
            headers: needsAuthHeader ? {'Authorization': 'Token ${esv.apiKey}'} : null,
            tag: mediaItem,
          );
          await _audioPlayer.setAudioSource(source);
        } else {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play();
      } catch (e, stack) {
        AppLogger.error(
          'Failed to seek/play next iteration $nextIteration, recovering audio source',
          error: e,
          stackTrace: stack,
        );
        await loadChapter(state.currentChapter);
      }
    } else {
      await _flutterTts.speak(_spokenText(state.currentChapter.textContent));
    }
  }
}
