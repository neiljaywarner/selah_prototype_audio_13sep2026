import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/bible_canon.dart';
import '../../../core/karaoke/timestamp_loader.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/preferences/user_preferences.dart';
import '../domain/audio_mode.dart';
import '../domain/bible_translation.dart';
import '../domain/chapter_info.dart';
import 'chapter_player_state.dart';

final chapterPlayerProvider = NotifierProvider<ChapterPlayerNotifier, ChapterPlayerState>(
  ChapterPlayerNotifier.new,
);

class ChapterPlayerNotifier extends Notifier<ChapterPlayerState> {
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;
  late final Dio _dio;
  Timer? _gapTimer;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _eventSub;
  List<VerseTimestamp>? _currentTimestamps;

  @override
  ChapterPlayerState build() {
    _audioPlayer = AudioPlayer();
    _flutterTts = FlutterTts();
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBibleBaseUrl,
        headers: {'api-key': kApiBibleKey, 'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          AppLogger.info('Dio network notice: ${e.message}');
          return handler.next(e);
        },
      ),
    );

    _initAudioListeners();
    _initTtsEngine();

    ref.onDispose(() {
      _posSub?.cancel();
      _durSub?.cancel();
      _stateSub?.cancel();
      _eventSub?.cancel();
      _gapTimer?.cancel();
      _audioPlayer.dispose();
      _flutterTts.stop().catchError((_) => 0);
    });

    String initialTranslation = 'BSB';
    try {
      final userPrefs = ref.watch(userPreferencesProvider);
      final saved = userPrefs.lastTranslationCode;
      if (saved != null && saved.isNotEmpty) {
        initialTranslation = BibleTranslation.fromCode(saved).code;
      }
    } catch (_) {
      // In tests or if provider not yet overridden, fall back cleanly to BSB
    }

    return ChapterPlayerState(
      currentChapter: kFeaturedChapters[0],
      activeTranslation: initialTranslation,
    );
  }

  void _initAudioListeners() {
    _posSub = _audioPlayer.positionStream.listen((pos) {
      if (state.audioMode == AudioMode.narrator) {
        int hStart = 0;
        int hEnd = 0;
        if (_currentTimestamps != null) {
          final posMs = pos.inMilliseconds;
          for (final vt in _currentTimestamps!) {
            if (posMs >= vt.startMs && posMs <= vt.endMs) {
              hStart = 0;
              hEnd = vt.text.length;
              break;
            }
          }
        }
        state = state.copyWith(
          position: pos,
          highlightStart: hStart > 0 ? hStart : state.highlightStart,
          highlightEnd: hEnd > 0 ? hEnd : state.highlightEnd,
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

      if (playerState.processingState == ProcessingState.completed && state.isPlaying) {
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
          _switchToTtsFallback(
            'Audio stream blocked or unavailable. Switched to Text-to-Speech (TTS).',
          );
        }
      },
    );
  }

  Future<void> _initTtsEngine() async {
    try {
      await _flutterTts.setLanguage('en-US');
      // Gentle meditation speech rate and pitch
      await _flutterTts.setSpeechRate(0.38);
      await _flutterTts.setPitch(0.95);

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

      _flutterTts.setErrorHandler((_) {
        if (state.audioMode == AudioMode.tts && state.isPlaying) {
          _handleChapterPlaybackComplete();
        }
      });
    } catch (e) {
      AppLogger.info('TTS engine notice: $e');
    }
  }

  String _fallbackChapterText(String bookCode, int chapterNumber, String bookName) {
    for (final preset in kFeaturedChapters) {
      if (preset.bookCode.toUpperCase() == bookCode.toUpperCase() &&
          preset.chapterNumber == chapterNumber) {
        return preset.textContent;
      }
    }
    if (state.currentChapter.bookCode.toUpperCase() == bookCode.toUpperCase() &&
        state.currentChapter.chapterNumber == chapterNumber &&
        state.currentChapter.textContent.isNotEmpty) {
      return state.currentChapter.textContent;
    }
    return '${BibleCanon.findBook(bookCode)?.name ?? bookName} Chapter $chapterNumber.\n\n'
        '"In the beginning was the Word, and the Word was with God, and the Word was God."';
  }

  Future<void> routeAndPlayChapter({
    required String bookCode,
    required int chapterNumber,
    required String bookName,
  }) async {
    await stopAllPlayback();
    if (!ref.mounted) return;

    final fallbackText = _fallbackChapterText(bookCode, chapterNumber, bookName);

    state = state.copyWith(
      currentChapter: ChapterInfo(
        bookCode: bookCode.toUpperCase(),
        bookName: bookName,
        chapterNumber: chapterNumber,
        audioStreamUrl: '',
        textContent: fallbackText,
      ),
      isLoading: true,
      clearLastError: true,
      clearInfoNotice: true,
      highlightStart: 0,
      highlightEnd: 0,
    );

    final translation = state.translation;

    // Rule 1: translation has no human narrator for this testament (e.g. WEB OT) -> TTS
    if (!translation.hasNarratorFor(bookCode)) {
      AppLogger.info(
        'Routing: ${translation.code} has no narrator for $bookCode $chapterNumber -> Using standard TTS engine.',
      );

      final chapterText = await _fetchChapterText(bookCode, chapterNumber) ?? fallbackText;

      final dynamicChapter = ChapterInfo(
        bookCode: bookCode.toUpperCase(),
        bookName: bookName,
        chapterNumber: chapterNumber,
        audioStreamUrl: '',
        textContent: chapterText,
      );

      final testament = BibleCanon.isOldTestament(bookCode) ? 'OT' : 'NT';
      state = state.copyWith(
        currentChapter: dynamicChapter,
        audioMode: AudioMode.tts,
        infoNotice:
            '${translation.fullName} (${translation.code}) has no $testament narrator on API.Bible — narrating with Text-to-Speech (TTS).',
      );

      await _playTts(chapterText);
      return;
    }

    // Rule 2: translation has a narrator for this testament (BSB OT+NT, NIV OT+NT, WEB NT)
    final bibleId = translation.audioBibleId;
    final chapterId = '${bookCode.toUpperCase()}.$chapterNumber';
    final url = '/audio-bibles/$bibleId/chapters/$chapterId';

    AppLogger.info('Fetching ${translation.code} narrator stream for $chapterId ($bibleId) from API.Bible...');

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final String? streamUrl = data['resourceUrl'];
        _recordFumsToken(response.data, kind: 'audio', chapterId: chapterId);

        if (streamUrl != null && streamUrl.isNotEmpty) {
          final fetchedText = await _fetchChapterText(bookCode, chapterNumber) ?? fallbackText;

          final dynamicChapter = ChapterInfo(
            bookCode: bookCode.toUpperCase(),
            bookName: bookName,
            chapterNumber: chapterNumber,
            audioStreamUrl: streamUrl,
            textContent: fetchedText,
          );

          state = state.copyWith(audioMode: AudioMode.narrator, clearInfoNotice: true);

          await loadChapter(dynamicChapter);
          return;
        }
      }
      throw Exception('Resource URL empty for $chapterId');
    } catch (e, stack) {
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
      final cachedText = ref.read(offlineScriptureCacheProvider).getOfflineText(
            translation.code,
            bookCode,
            chapterNumber,
          ) ?? fallbackText;
      _switchToTtsFallback(
        'Offline / Airplane Mode: Narrating ${translation.fullName} (${translation.code}) scripture via Text-to-Speech (TTS).',
        overrideText: cachedText,
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

  Future<String?> _fetchChapterText(String bookCode, int chapterNumber) async {
    // Check offline disk cache first for public domain BSB / WEB
    try {
      final cache = ref.read(offlineScriptureCacheProvider);
      final cached = cache.getOfflineText(state.activeTranslation, bookCode, chapterNumber);
      if (cached != null && cached.trim().isNotEmpty) {
        return cached;
      }
    } catch (_) {}

    if (kApiBibleKey == 'REDACTED' || kApiBibleKey.isEmpty) return null;
    try {
      final textBibleId = state.translation.textBibleId;
      final passageId = '${bookCode.toUpperCase()}.$chapterNumber';
      final res = await _dio.get(
        '/bibles/$textBibleId/passages/$passageId',
        queryParameters: {'content-type': 'text', 'include-verse-numbers': 'false'},
      );
      if (res.statusCode == 200 && res.data != null) {
        _recordFumsToken(res.data, kind: 'text', chapterId: passageId);
        final content = res.data['data']?['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          final cleaned = content.replaceAll(RegExp(r'\s+'), ' ').trim();
          try {
            ref.read(offlineScriptureCacheProvider).saveOfflineToDisk(
              state.activeTranslation,
              bookCode,
              chapterNumber,
              cleaned,
            );
          } catch (_) {}
          return cleaned;
        }
      }
    } catch (_) {}
    return null;
  }
  Future<void> fetchAndPlaySingleVerse(String query) async {
    await stopAllPlayback();

    state = state.copyWith(
      isLoading: true,
      clearLastError: true,
      clearInfoNotice: true,
      audioMode: AudioMode.tts,
      highlightStart: 0,
      highlightEnd: 0,
    );

    try {
      final res = await _dio.get('https://bible-api.com/${Uri.encodeComponent(query.trim())}');
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

        await _playTts(verseStr);
        return;
      }
    } catch (e) {
      AppLogger.error('Single verse fetch failed', error: e);
    }

    _switchToTtsFallback('Could not load online verse. Narrating fallback meditation verse.');
  }

  Future<void> stopAllPlayback() async {
    _gapTimer?.cancel();
    try {
      await _flutterTts.stop();
    } catch (_) {}
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (!ref.mounted) return;
    state = state.copyWith(isPlaying: false, isPausedInGap: false);
  }

  Future<void> _playTts(String text) async {
    await stopAllPlayback();
    if (!ref.mounted) return;

    state = state.copyWith(
      isLoading: false,
      isPlaying: true,
      isPausedInGap: false,
      duration: Duration(seconds: (text.split(' ').length * 0.45).ceil()),
      position: Duration.zero,
    );

    AppLogger.logEvent('play_tts', {
      'chapter': state.currentChapter.reference,
      'translation': state.activeTranslation,
    });

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      AppLogger.error('TTS speech failed', error: e);
      state = state.copyWith(isPlaying: false, lastError: 'TTS playback error: $e');
    }
  }

  void _switchToTtsFallback(String notice, {String? overrideText}) {
    if (!ref.mounted) return;
    final text = overrideText ?? state.currentChapter.textContent;
    state = state.copyWith(
      isLoading: false,
      audioMode: AudioMode.tts,
      infoNotice: notice,
      currentChapter: state.currentChapter.copyWith(textContent: text),
    );
    _playTts(text);
  }

  Future<void> loadChapter(ChapterInfo chapter) async {
    await stopAllPlayback();
    if (!ref.mounted) return;

    _currentTimestamps = await TimestampLoaderService.loadChapterTimestamps(
      translation: state.activeTranslation,
      bookCode: chapter.bookCode,
      chapterNumber: chapter.chapterNumber,
    );
    if (_currentTimestamps != null && _currentTimestamps!.isNotEmpty) {
      AppLogger.info(
        'WhisperX timestamps loaded for ${chapter.reference}: ${_currentTimestamps!.length} verses.',
      );
    }

    state = state.copyWith(
      currentChapter: chapter,
      audioMode: AudioMode.narrator,
      isLoading: true,
      isPlaying: false,
      isPausedInGap: false,
      currentIteration: 1,
      position: Duration.zero,
      duration: Duration.zero,
      clearLastError: true,
    );

    AppLogger.logEvent('play_chapter', {
      'translation': state.activeTranslation,
      'book': chapter.bookCode,
      'chapter': chapter.chapterNumber,
      'audio_url': chapter.audioStreamUrl,
    });

    if (chapter.audioStreamUrl.isEmpty) {
      await routeAndPlayChapter(
        bookCode: chapter.bookCode,
        chapterNumber: chapter.chapterNumber,
        bookName: chapter.bookName,
      );
      return;
    }

    try {
      final dur = await _audioPlayer.setUrl(chapter.audioStreamUrl);
      state = state.copyWith(isLoading: false, duration: dur ?? Duration.zero);
      play();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to set audio source URL in player',
        error: e,
        stackTrace: stack,
        properties: {
          'book_code': chapter.bookCode,
          'chapter': chapter.chapterNumber,
          'translation': state.activeTranslation,
          'audio_mode': state.audioMode.name,
        },
      );
      _switchToTtsFallback('Audio stream blocked or failed. Switched to Text-to-Speech (TTS).');
    }
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  Future<void> play() async {
    if (state.isPausedInGap) {
      _gapTimer?.cancel();
      state = state.copyWith(isPausedInGap: false, isPlaying: true);
      if (state.audioMode == AudioMode.narrator) {
        _audioPlayer.play();
      } else {
        _flutterTts.speak(state.currentChapter.textContent);
      }
      return;
    }

    if (state.audioMode == AudioMode.narrator && state.currentChapter.audioStreamUrl.isEmpty) {
      await routeAndPlayChapter(
        bookCode: state.currentChapter.bookCode,
        chapterNumber: state.currentChapter.chapterNumber,
        bookName: state.currentChapter.bookName,
      );
      return;
    }

    state = state.copyWith(isPlaying: true, clearLastError: true);

    if (state.audioMode == AudioMode.tts) {
      await _flutterTts.speak(state.currentChapter.textContent);
      return;
    }

    if (state.position >= state.duration && state.duration > Duration.zero) {
      await _audioPlayer.seek(Duration.zero);
    }

    try {
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
      _switchToTtsFallback('Playback failed. Switched to Text-to-Speech (TTS).');
    }
  }

  Future<void> pause() async {
    _gapTimer?.cancel();
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

  void setPauseGap(int seconds) {
    state = state.copyWith(pauseGapSeconds: seconds);
    AppLogger.logEvent('change_setting', {'setting': 'pauseGapSeconds', 'value': seconds});
  }

  void setTranslation(String translation) {
    final target = BibleTranslation.fromCode(translation);
    if (state.activeTranslation == target.code) return;

    final previousTranslation = state.activeTranslation;
    state = state.copyWith(activeTranslation: target.code);

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

    // Re-route current chapter with new translation
    routeAndPlayChapter(
      bookCode: state.currentChapter.bookCode,
      chapterNumber: state.currentChapter.chapterNumber,
      bookName: state.currentChapter.bookName,
    );
  }

  void toggleKaraoke(bool enabled) {
    state = state.copyWith(karaokeEnabled: enabled);
    AppLogger.logEvent('toggle_karaoke', {'enabled': enabled});
  }

  void _handleChapterPlaybackComplete() {
    if (state.repetitions != -1 && state.currentIteration >= state.repetitions) {
      AppLogger.info('Completed all ${state.repetitions} repetitions.');
      state = state.copyWith(
        isPlaying: false,
        currentIteration: 1,
        highlightStart: 0,
        highlightEnd: 0,
      );
      _audioPlayer.seek(Duration.zero);
      return;
    }

    state = state.copyWith(isPausedInGap: true, highlightStart: 0, highlightEnd: 0);
    AppLogger.info('Entering silent reflection gap (${state.pauseGapSeconds}s)...');

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
    final next = !state.shuffleTranslations;
    state = state.copyWith(shuffleTranslations: next);
    AppLogger.logEvent('toggle_shuffle_translations', {'enabled': next});
    if (next) {
      cycleNextTranslation();
    }
  }

  void cycleNextTranslation() {
    const list = ['BSB', 'WEB', 'NIV'];
    final idx = list.indexOf(state.activeTranslation);
    final next = list[(idx + 1) % list.length];
    setTranslation(next);
  }

  Future<void> _startNextIteration() async {
    AppLogger.info('Starting repetition ${state.currentIteration + 1}');
    state = state.copyWith(
      currentIteration: state.currentIteration + 1,
      isPausedInGap: false,
      isPlaying: true,
    );

    if (state.shuffleTranslations) {
      cycleNextTranslation();
      return;
    }

    if (state.audioMode == AudioMode.narrator) {
      await _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
    } else {
      await _flutterTts.speak(state.currentChapter.textContent);
    }
  }
}
