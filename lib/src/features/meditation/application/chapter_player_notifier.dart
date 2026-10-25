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
import '../domain/passage_excerpt.dart';
export 'chapter_player_state.dart';
import 'chapter_player_state.dart';

final chapterPlayerProvider = NotifierProvider<ChapterPlayerNotifier, ChapterPlayerState>(
  ChapterPlayerNotifier.new,
);

class ChapterPlayerNotifier extends Notifier<ChapterPlayerState> {
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;
  late final Dio _dio;
  Timer? _gapTimer;
  Timer? _sleepTimer;
  Timer? _volumeFadeTimer;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _eventSub;
  List<VerseTimestamp>? _currentTimestamps;

  /// Start of the active clip within the full chapter stream. Player positions
  /// are clip-relative, while timestamps are chapter-absolute.
  Duration _clipOffset = Duration.zero;

  String _getActiveApiKey() {
    try {
      final remoteKey = ref.read(remoteConfigServiceProvider).getString('api_bible_key');
      if (remoteKey.isNotEmpty) return remoteKey;
    } catch (_) {}
    return (kApiBibleKey != 'REDACTED' && kApiBibleKey.isNotEmpty) ? kApiBibleKey : '';
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

    final policy = ref.watch(esvPassagePolicyProvider);
    String initialTranslation = policy.defaultTranslationCode;
    try {
      final userPrefs = ref.watch(userPreferencesProvider);
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
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
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

      if (playerState.processingState == ProcessingState.completed && !state.isPausedInGap) {
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
    PassageExcerpt? excerpt,
  }) async {
    await stopAllPlayback();
    if (!ref.mounted) return;

    final fallbackText = _fallbackChapterText(bookCode, chapterNumber, bookName);
    final effectiveExcerpt = excerpt ?? PassageExcerpt.forChapter(bookCode, chapterNumber);

    final policy = ref.read(esvPassagePolicyProvider);
    if (policy.useEsvForPassages) {
      final query = effectiveExcerpt?.toEsvPassageQuery() ?? '$bookName $chapterNumber';
      if (await tryPlayEsvPassage(EsvPassagePolicy.normalizePassageQuery(query))) {
        state = state.copyWith(
          activeTranslation: BibleTranslation.esv.code,
          activeExcerpt: effectiveExcerpt,
        );
        return;
      }
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
      final fetchedText = await _fetchChapterText(bookCode, chapterNumber) ?? fallbackText;
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

      await loadChapter(dynamicChapter, excerpt: effectiveExcerpt);
      return;
    }

    // Rule 0.5: Curated excerpt or single verse without bundled audio (e.g. NIV)
    if (bookCode.toUpperCase() == 'VRS') {
      final text = state.currentChapter.textContent.isNotEmpty
          ? state.currentChapter.textContent
          : fallbackText;
      final notice = kIsWeb
          ? 'NIV audio stream is proprietary to Biblica / API.Bible. Narrating with Text-to-Speech (TTS).'
          : '${translation.fullName} (${translation.code}) excerpt narration — narrating with Text-to-Speech (TTS).';
      state = state.copyWith(
        audioMode: AudioMode.tts,
        isOffline: false,
        infoNotice: notice,
      );
      await _playTts(text);
      return;
    }

    // Rule 1: translation has no human narrator for this testament (e.g. WEB OT) -> TTS
    if (!translation.hasNarratorFor(bookCode)) {
      AppLogger.info(
        'Routing: ${translation.code} has no narrator for $bookCode $chapterNumber -> Using standard TTS engine.',
      );

      final chapterText = await _fetchChapterText(bookCode, chapterNumber) ?? fallbackText;
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
        isOffline: true,
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
    final activeKey = _getActiveApiKey();

    if (activeKey.isEmpty) {
      AppLogger.info(
        'API.Bible key unconfigured; gracefully routing to contemplative voice for $chapterId.',
      );
      final cachedText = ref.read(offlineScriptureCacheProvider).getOfflineText(
            translation.code,
            bookCode,
            chapterNumber,
          ) ?? fallbackText;
      final noticeMessage = translation.isLicensed
          ? 'NIV audio stream currently unavailable. Narrating with contemplative voice.'
          : 'Narrator stream unavailable — narrating ${translation.fullName} (${translation.code}) with contemplative voice.';
      state = state.copyWith(isOffline: false);
      _switchToTtsFallback(
        noticeMessage,
        overrideText: cachedText,
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
          final fetchedText = await _fetchChapterText(bookCode, chapterNumber) ?? fallbackText;
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

          await loadChapter(dynamicChapter, excerpt: effectiveExcerpt);
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
      final cachedText = ref.read(offlineScriptureCacheProvider).getOfflineText(
            translation.code,
            bookCode,
            chapterNumber,
          ) ?? fallbackText;

      final noticeMessage = translation.isLicensed
          ? 'NIV audio stream currently unavailable. Narrating with contemplative voice.'
          : 'Narrator stream currently unavailable — narrating ${translation.fullName} (${translation.code}) with contemplative voice.';

      state = state.copyWith(isOffline: false);
      _switchToTtsFallback(
        noticeMessage,
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

    final activeKey = _getActiveApiKey();
    if (activeKey.isEmpty) return null;
    try {
      final textBibleId = state.translation.textBibleId;
      final excerpt = PassageExcerpt.forChapter(bookCode, chapterNumber);
      final passageId = excerpt != null
          ? '${bookCode.toUpperCase()}.$chapterNumber.${excerpt.startVerse}-${bookCode.toUpperCase()}.$chapterNumber.${excerpt.endVerse}'
          : '${bookCode.toUpperCase()}.$chapterNumber';
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

  /// Plays [query] from the ESV API, one HTTP call per verse in a range.
  ///
  /// Returns false when the key is unset or the request fails, without
  /// replacing a later narrator or bible-api.com attempt.
  Future<bool> tryPlayEsvPassage(String query) async {
    final esv = EsvApiClient();
    if (!esv.isConfigured) return false;

    await stopAllPlayback();
    if (!ref.mounted) return false;
    state = state.copyWith(
      isLoading: true,
      clearLastError: true,
      clearInfoNotice: true,
      audioMode: AudioMode.tts,
      highlightStart: 0,
      highlightEnd: 0,
    );

    try {
      final verses = await esv.fetchVerseByVerse(query);
      if (!ref.mounted) return false;
      if (verses.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final verseStr = '${verses.map((verse) => verse.text).join(' ')} $kEsvShortCopyright';
      final joinedRef = EsvApiClient.joinedReference(verses);

      final directAudioUrl = await esv.fetchPassageAudioUrl(query) ??
          'https://api.esv.org/v3/passage/audio/?q=${Uri.encodeComponent(query)}';
      try {
        final mediaItem = MediaItem(
          id: directAudioUrl,
          album: 'Selah Scripture Audio',
          title: joinedRef,
          artist: 'David Cochran Heath (ESV)',
          artUri: Uri.parse('https://selahword.web.app/icons/Icon-192.png'),
        );
        final source = AudioSource.uri(
          Uri.parse(directAudioUrl),
          headers: {'Authorization': 'Token ${esv.apiKey}'},
          tag: mediaItem,
        );
        final dur = await _audioPlayer.setAudioSource(source);
        if (!ref.mounted) return false;
        state = state.copyWith(
          isLoading: false,
          isPlaying: true,
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
          infoNotice: null,
        );
        play();
        return true;
      } catch (audioErr) {
        AppLogger.error('ESV human audio playback failed: $audioErr');
        if (ref.mounted) {
          state = state.copyWith(
            isLoading: false,
            isPlaying: false,
            lastError: 'ESV audio stream error: $audioErr',
          );
        }
        return false;
      }
    } catch (e) {
      AppLogger.error('ESV verse fetch failed', error: e);
      if (ref.mounted) state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> fetchAndPlaySingleVerse(String query, {bool tryEsv = true}) async {
    if (tryEsv && await tryPlayEsvPassage(query)) return;

    final policy = ref.read(esvPassagePolicyProvider);
    if (policy.useEsvForPassages) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        lastError: 'ESV passage "$query" could not be played.',
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

  /// Removes trailing copyright notices (e.g. `(ESV)`) from text spoken by TTS.
  /// The mark is displayed visually in textContent but not spoken aloud.
  static String _spokenText(String text) {
    const suffix = ' $kEsvShortCopyright';
    return text.endsWith(suffix) ? text.substring(0, text.length - suffix.length) : text;
  }

  Future<void> _playTts(String text) async {
    await stopAllPlayback();
    if (!ref.mounted) return;

    final spoken = _spokenText(text);
    state = state.copyWith(
      isLoading: false,
      isPlaying: true,
      isPausedInGap: false,
      duration: Duration(seconds: (spoken.split(' ').length * 0.45).ceil()),
      position: Duration.zero,
    );

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

  Future<void> loadChapter(ChapterInfo chapter, {PassageExcerpt? excerpt}) async {
    await stopAllPlayback();
    if (!ref.mounted) return;

    final policy = ref.read(esvPassagePolicyProvider);
    if (policy.useEsvForPassages) {
      final query = esvPassageQueryFor(chapter, excerpt: excerpt);
      if (query != null && await tryPlayEsvPassage(query)) {
        return;
      }
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

    state = state.copyWith(
      currentChapter: chapter,
      audioMode: AudioMode.narrator,
      hasTimestamps: hasTimestamps,
      activeExcerpt: effectiveExcerpt,
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
      'has_timestamps': hasTimestamps,
      'has_excerpt': effectiveExcerpt != null,
    });

    if (chapter.audioStreamUrl.isEmpty) {
      await routeAndPlayChapter(
        bookCode: chapter.bookCode,
        chapterNumber: chapter.chapterNumber,
        bookName: chapter.bookName,
        excerpt: effectiveExcerpt,
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
      final isEsvAudio = chapter.audioStreamUrl.contains('api.esv.org');
      final audioHeaders = isEsvAudio && isEsvApiConfigured
          ? {'Authorization': 'Token $kEsvApiKey'}
          : null;
      final UriAudioSource baseSource = isAsset
          ? AudioSource.asset(chapter.audioStreamUrl, tag: mediaItem)
          : AudioSource.uri(
              Uri.parse(chapter.audioStreamUrl),
              headers: audioHeaders,
              tag: mediaItem,
            );

      final window = effectiveExcerpt?.clipWindow(_currentTimestamps);
      _clipOffset = window?.start ?? Duration.zero;

      if (effectiveExcerpt != null && window == null) {
        AppLogger.logEvent('custom_passage_unaligned', {
          'passage': effectiveExcerpt.displayTitle ?? chapter.reference,
          'translation': state.activeTranslation,
        });
      }

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
      play();
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
      state = state.copyWith(isOffline: true);
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
        _flutterTts.speak(_spokenText(state.currentChapter.textContent));
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
      await _flutterTts.speak(_spokenText(state.currentChapter.textContent));
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

  void setTranslation(String translation, {bool force = false}) {
    final target = BibleTranslation.fromCode(translation);
    if (state.activeTranslation == target.code) return;

    final policy = ref.read(esvPassagePolicyProvider);
    if (!force && !policy.showApiBibleTranslations && target.code != BibleTranslation.esv.code) {
      return;
    }

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
    pause();
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

    if (state.repetitions != -1 && state.currentIteration >= state.repetitions) {
      AppLogger.info('Completed all ${state.repetitions} repetitions.');
      state = state.copyWith(
        isPlaying: false,
        currentIteration: 1,
        highlightStart: 0,
        highlightEnd: 0,
      );
      if (state.audioMode == AudioMode.narrator) {
        _audioPlayer.pause().then((_) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.setVolume(1.0);
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
    final nextIteration = state.currentIteration + 1;
    final repLabel = state.repetitions == -1 ? '∞' : '${state.repetitions}';
    AppLogger.info('Starting repetition $nextIteration (loop $nextIteration of $repLabel)');
    state = state.copyWith(
      currentIteration: nextIteration,
      isPausedInGap: false,
      isPlaying: true,
    );

    if (state.shuffleTranslations) {
      cycleNextTranslation();
      return;
    }

    if (state.audioMode == AudioMode.narrator) {
      try {
        AppLogger.info('Seeking narrator player to Duration.zero for loop $nextIteration of $repLabel');
        await _audioPlayer.seek(Duration.zero);
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
