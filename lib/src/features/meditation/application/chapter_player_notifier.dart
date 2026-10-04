import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/chapter_info.dart';
import 'chapter_player_state.dart';

final chapterPlayerProvider = NotifierProvider<ChapterPlayerNotifier, ChapterPlayerState>(
  ChapterPlayerNotifier.new,
);

class ChapterPlayerNotifier extends Notifier<ChapterPlayerState> {
  late final AudioPlayer _audioPlayer;
  late final Dio _dio;
  Timer? _gapTimer;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _eventSub;

  @override
  ChapterPlayerState build() {
    _audioPlayer = AudioPlayer();
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBibleBaseUrl,
        headers: {'api-key': kApiBibleKey, 'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );

    _initAudioListeners();

    ref.onDispose(() {
      _posSub?.cancel();
      _durSub?.cancel();
      _stateSub?.cancel();
      _eventSub?.cancel();
      _gapTimer?.cancel();
      _audioPlayer.dispose();
    });

    return ChapterPlayerState(currentChapter: kFeaturedChapters[0]);
  }

  void _initAudioListeners() {
    _posSub = _audioPlayer.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durSub = _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        AppLogger.info('Audio duration resolved: ${dur.inSeconds}s');
        state = state.copyWith(duration: dur);
      }
    });

    _stateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final pStateStr = playerState.processingState.toString().split('.').last;
      AppLogger.info(
        'Audio Player State -> playing: ${playerState.playing}, processing: $pStateStr',
      );

      state = state.copyWith(isPlaying: playerState.playing, processingStateName: pStateStr);

      if (playerState.processingState == ProcessingState.completed && state.isPlaying) {
        AppLogger.info('Chapter completed iteration ${state.currentIteration}');
        _handleChapterPlaybackComplete();
      }
    });

    _eventSub = _audioPlayer.playbackEventStream.listen(
      (event) {
        AppLogger.info('PlaybackEvent: buffered=${event.bufferedPosition.inSeconds}s');
      },
      onError: (Object e, StackTrace stack) {
        AppLogger.error('PlaybackEventStream error', error: e, stackTrace: stack);
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          lastError: 'Playback stream error: $e',
        );
      },
    );
  }

  Future<void> fetchAndPlayApiBibleChapter({
    required String bookCode,
    required int chapterNumber,
    required String bookName,
  }) async {
    state = state.copyWith(isLoading: true, lastError: null);
    final chapterId = '${bookCode.toUpperCase()}.$chapterNumber';
    final bibleId = state.activeTranslation == 'WEB' ? kWebAudioBibleId : kBsbAudioBibleId;
    final url = '/audio-bibles/$bibleId/chapters/$chapterId';

    AppLogger.info(
      'curl "$kApiBibleBaseUrl$url" --header "Accept: application/json" --header "api-key: ${kApiBibleKey.length >= 6 ? kApiBibleKey.substring(0, 6) : "REDACTED"}..."',
    );

    try {
      final response = await _dio.get(url);
      AppLogger.info('API.Bible HTTP Response: Status ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final String? streamUrl = data['resourceUrl'];
        final String? expiresAt = data['expiresAt'];

        if (streamUrl != null && streamUrl.isNotEmpty) {
          AppLogger.info('Retrieved audio stream URL (Expires $expiresAt): $streamUrl');

          final dynamicChapter = ChapterInfo(
            bookCode: bookCode,
            bookName: bookName,
            chapterNumber: chapterNumber,
            audioStreamUrl: streamUrl,
            textContent:
                '${state.activeTranslation} — Live REST Audio Stream from API.Bible ($chapterId).',
          );
          await loadChapter(dynamicChapter);
          return;
        }
      }
      throw Exception('API.Bible response missing resourceUrl for chapter $chapterId.');
    } catch (e, stack) {
      AppLogger.error('API.Bible fetch failed for chapter $chapterId', error: e, stackTrace: stack);
      state = state.copyWith(lastError: 'API.Bible fetch failed ($e). Loaded fallback chapter.');
      await loadChapter(kFeaturedChapters[0]);
    }
  }

  Future<void> loadChapter(ChapterInfo chapter) async {
    _gapTimer?.cancel();
    AppLogger.info('Loading chapter ${chapter.reference} (URL: ${chapter.audioStreamUrl})');

    try {
      await _audioPlayer.stop();
    } catch (e) {
      AppLogger.info('Audio stop notice: $e');
    }

    state = state.copyWith(
      currentChapter: chapter,
      isLoading: true,
      isPlaying: false,
      isPausedInGap: false,
      currentIteration: 1,
      position: Duration.zero,
      duration: Duration.zero,
      lastError: null,
    );

    AppLogger.logEvent('play_chapter', {
      'translation': state.activeTranslation,
      'book': chapter.bookCode,
      'chapter': chapter.chapterNumber,
      'audio_url': chapter.audioStreamUrl,
    });

    try {
      AppLogger.info('Setting audio source URL...');
      final dur = await _audioPlayer.setUrl(chapter.audioStreamUrl);
      AppLogger.info('Audio source set successfully. Duration: $dur');

      state = state.copyWith(isLoading: false, duration: dur ?? Duration.zero);
      play();
    } catch (e, stack) {
      AppLogger.error('Failed to set audio source URL in player', error: e, stackTrace: stack);

      if (chapter.audioStreamUrl != kFeaturedChapters[0].audioStreamUrl) {
        AppLogger.info('Triggering CORS-friendly fallback audio track...');
        try {
          final fallbackDur = await _audioPlayer.setUrl(kFeaturedChapters[0].audioStreamUrl);
          state = state.copyWith(
            isLoading: false,
            duration: fallbackDur ?? Duration.zero,
            lastError: 'Primary audio URL blocked or failed ($e). Loaded CORS fallback.',
          );
          play();
          return;
        } catch (fallbackErr) {
          AppLogger.error('Fallback audio stream also failed', error: fallbackErr);
        }
      }

      state = state.copyWith(isLoading: false, lastError: 'Audio load error: $e');
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
      _audioPlayer.play();
      return;
    }

    if (state.position >= state.duration && state.duration > Duration.zero) {
      await _audioPlayer.seek(Duration.zero);
    }

    try {
      state = state.copyWith(isPlaying: true, lastError: null);
      AppLogger.info('Executing _audioPlayer.play()...');
      await _audioPlayer.play();
    } catch (e, stack) {
      AppLogger.error('Playback trigger failed', error: e, stackTrace: stack);
      state = state.copyWith(isPlaying: false, lastError: 'Playback error: $e');
    }
  }

  Future<void> pause() async {
    _gapTimer?.cancel();
    await _audioPlayer.pause();
    state = state.copyWith(isPlaying: false, isPausedInGap: false);
  }

  void seek(Duration pos) {
    AppLogger.info('Seeking to ${pos.inSeconds}s');
    _audioPlayer.seek(pos);
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
    state = state.copyWith(activeTranslation: translation);
    AppLogger.logEvent('change_translation', {'translation': translation});
  }

  void toggleKaraoke(bool enabled) {
    state = state.copyWith(karaokeEnabled: enabled);
    AppLogger.logEvent('toggle_karaoke', {
      'enabled': enabled,
      'chapter': state.currentChapter.reference,
    });
  }

  void _handleChapterPlaybackComplete() {
    if (state.repetitions != -1 && state.currentIteration >= state.repetitions) {
      AppLogger.info('Completed all ${state.repetitions} repetitions.');
      state = state.copyWith(isPlaying: false, currentIteration: 1);
      _audioPlayer.seek(Duration.zero);
      return;
    }

    state = state.copyWith(isPausedInGap: true);
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

  Future<void> _startNextIteration() async {
    AppLogger.info('Starting repetition ${state.currentIteration + 1}');
    state = state.copyWith(
      currentIteration: state.currentIteration + 1,
      isPausedInGap: false,
      isPlaying: true,
    );
    await _audioPlayer.seek(Duration.zero);
    _audioPlayer.play();
  }
}
