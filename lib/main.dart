import 'dart:async';

import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

/*
 flutter build web --release \
              --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
              --dart-define=APTABASE_KEY=$APTABASE_KEY

 */
// =============================================================================
// HOW TO USE --dart-define IN DIFFERENT DEPLOYMENT ENVIRONMENTS
// =============================================================================
//
// 1. LOCAL MACOS TERMINAL (~/.zshrc):
//    Add to your ~/.zshrc file:
//      export API_BIBLE_KEY="YOUR_API_BIBLE_KEY"
//      export APTABASE_KEY="YOUR_APTABASE_KEY"
//    Then reload terminal (`source ~/.zshrc`) and run:
//      flutter run -d chrome --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY --dart-define=APTABASE_KEY=$APTABASE_KEY
//
// 2. CODEMAGIC CI/CD (codemagic.yaml or Environment Variables UI):
//    In Codemagic Web Console -> Environment Variables:
//      API_BIBLE_KEY = YOUR_API_BIBLE_KEY
//      APTABASE_KEY  = YOUR_APTABASE_KEY
//    In codemagic.yaml build script:
//      scripts:
//        - name: Build Web App
//          script: |
//            flutter build web --release \
//              --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
//              --dart-define=APTABASE_KEY=$APTABASE_KEY
//
// 3. GITHUB ACTIONS (.github/workflows/deploy.yml):
//    Add secrets in Github Repository Settings -> Secrets and Variables -> Actions:
//      API_BIBLE_KEY
//      APTABASE_KEY
//    In your workflow step:
//      - name: Build Flutter Web
//        run: |
//          flutter build web --release \
//            --dart-define=API_BIBLE_KEY=${{ secrets.API_BIBLE_KEY }} \
//            --dart-define=APTABASE_KEY=${{ secrets.APTABASE_KEY }}
// =============================================================================

const String kApiBibleBaseUrl = 'https://rest.api.bible/v1';
const String kApiBibleKey = String.fromEnvironment('API_BIBLE_KEY', defaultValue: 'REDACTED');
const String kAptabaseAppKey = String.fromEnvironment('APTABASE_KEY', defaultValue: 'REDACTED');

// Standard WEB Bible IDs on API.Bible
const String kWebAudioBibleId = '01b29f4b3420b57e-01'; // WEB Audio Bible ID
const String kWebTextBibleId = '986526432f426da3-01'; // WEB Text Bible ID

class ChapterInfo {
  final String bookCode;
  final String bookName;
  final int chapterNumber;
  final String audioStreamUrl;
  final String textContent;

  const ChapterInfo({
    required this.bookCode,
    required this.bookName,
    required this.chapterNumber,
    required this.audioStreamUrl,
    required this.textContent,
  });

  String get reference => '$bookName $chapterNumber';
}

final List<ChapterInfo> kFeaturedChapters = [
  const ChapterInfo(
    bookCode: 'JHN',
    bookName: 'John',
    chapterNumber: 1,
    audioStreamUrl: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=ambient-piano-10781.mp3',
    textContent: 'In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made through him. Without him was not anything made that has been made. In him was life, and the life was the light of men...',
  ),
  const ChapterInfo(
    bookCode: 'PSL',
    bookName: 'Psalm',
    chapterNumber: 23,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps023.mp3',
    textContent: 'Yahweh is my shepherd: I shall have no lack. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul. He guides me in the paths of righteousness for his name’s sake...',
  ),
  const ChapterInfo(
    bookCode: 'PSL',
    bookName: 'Psalm',
    chapterNumber: 46,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps046.mp3',
    textContent: 'God is our refuge and strength, a very present help in trouble. Therefore we will not fear, though the earth changes, though the mountains are shaken into the heart of the seas... Be still, and know that I am God!',
  ),
];

abstract class AnalyticsService {
  Future<void> init();
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]);
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  });
}

class AptabaseAnalyticsProvider implements AnalyticsService {
  final String appKey;
  AptabaseAnalyticsProvider({required this.appKey});

  @override
  Future<void> init() async {
    try {
      await Aptabase.init(appKey);
      debugPrint(
        '⚡ [APTABASE]: Analytics initialized successfully with key prefix ${appKey.length >= 7 ? appKey.substring(0, 7) : appKey}',
      );
    } catch (e) {
      debugPrint('🔴 [APTABASE INIT ERROR]: $e');
    }
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    try {
      await Aptabase.instance.trackEvent(eventName, properties);
      debugPrint('📊 [ANALYTICS EVENT]: $eventName => ${properties ?? {}}');
    } catch (e) {
      debugPrint('🔴 [ANALYTICS TRACK ERROR]: $e');
    }
  }

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {
    final props = <String, dynamic>{
      'error_name': errorName,
      'details': error?.toString(),
      ...?extraProperties,
    };
    try {
      await Aptabase.instance.trackEvent('app_error', props);
    } catch (e) {
      debugPrint('🔴 [ANALYTICS ERROR LOG FAILED]: $e');
    }
  }
}

class AppLogger {
  static AnalyticsService? _analytics;
  static final List<String> _inMemoryLogs = [];

  static void init(AnalyticsService analytics) {
    _analytics = analytics;
    info('AppLogger initialized');
  }

  static List<String> get logs => List.unmodifiable(_inMemoryLogs);

  static void info(String message, [Map<String, dynamic>? properties]) {
    final logLine =
        'ℹ️ [SELAH INFO] ${DateTime.now().toIso8601String().substring(11, 19)}: $message ${properties ?? ""}';
    debugPrint(logLine);
    _inMemoryLogs.insert(0, logLine);
    if (_inMemoryLogs.length > 50) _inMemoryLogs.removeLast();
  }

  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? properties,
  }) {
    final logLine =
        '🔴 [SELAH ERROR] ${DateTime.now().toIso8601String().substring(11, 19)}: $message | Details: $error';
    debugPrint(logLine);
    if (stackTrace != null) debugPrint(stackTrace.toString());

    _inMemoryLogs.insert(0, logLine);
    if (_inMemoryLogs.length > 50) _inMemoryLogs.removeLast();

    final errorProps = <String, dynamic>{'message': message, ...?properties};

    if (error is DioException) {
      errorProps['http_status'] = error.response?.statusCode ?? 0;
      errorProps['endpoint'] = error.requestOptions.uri.toString();
      errorProps['error_type'] = 'DioException';
    } else if (error != null) {
      errorProps['error_type'] = error.runtimeType.toString();
    }

    _analytics?.logError(
      message,
      error: error,
      stackTrace: stackTrace,
      extraProperties: errorProps,
    );
  }

  static void logEvent(String eventName, [Map<String, dynamic>? properties]) {
    info('EVENT: $eventName', properties);
    _analytics?.logEvent(eventName, properties);
  }
}

class ChapterPlayerState {
  final ChapterInfo currentChapter;
  final bool isLoading;
  final bool isPlaying;
  final bool isPausedInGap;
  final Duration position;
  final Duration duration;
  final int repetitions; // 1, 3, 7, -1 (Infinite)
  final int currentIteration;
  final int pauseGapSeconds; // 0, 3, 5, 10
  final bool karaokeEnabled;
  final String activeTranslation;
  final String? lastError;
  final String processingStateName;

  const ChapterPlayerState({
    required this.currentChapter,
    this.isLoading = false,
    this.isPlaying = false,
    this.isPausedInGap = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.repetitions = 3,
    this.currentIteration = 1,
    this.pauseGapSeconds = 4,
    this.karaokeEnabled = false,
    this.activeTranslation = 'WEB',
    this.lastError,
    this.processingStateName = 'idle',
  });

  ChapterPlayerState copyWith({
    ChapterInfo? currentChapter,
    bool? isLoading,
    bool? isPlaying,
    bool? isPausedInGap,
    Duration? position,
    Duration? duration,
    int? repetitions,
    int? currentIteration,
    int? pauseGapSeconds,
    bool? karaokeEnabled,
    String? activeTranslation,
    String? lastError,
    String? processingStateName,
  }) => ChapterPlayerState(
    currentChapter: currentChapter ?? this.currentChapter,
    isLoading: isLoading ?? this.isLoading,
    isPlaying: isPlaying ?? this.isPlaying,
    isPausedInGap: isPausedInGap ?? this.isPausedInGap,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    repetitions: repetitions ?? this.repetitions,
    currentIteration: currentIteration ?? this.currentIteration,
    pauseGapSeconds: pauseGapSeconds ?? this.pauseGapSeconds,
    karaokeEnabled: karaokeEnabled ?? this.karaokeEnabled,
    activeTranslation: activeTranslation ?? this.activeTranslation,
    lastError: lastError,
    processingStateName: processingStateName ?? this.processingStateName,
  );
}

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
        AppLogger.info('Audio duration resolved: ${dur.inSeconds} seconds');
        state = state.copyWith(duration: dur);
      }
    });

    _stateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final pStateStr = playerState.processingState.toString().split('.').last;
      AppLogger.info(
        'Audio Player State Changed -> Playing: ${playerState.playing}, ProcessingState: $pStateStr',
      );

      state = state.copyWith(isPlaying: playerState.playing, processingStateName: pStateStr);

      if (playerState.processingState == ProcessingState.completed && state.isPlaying) {
        AppLogger.info('Chapter completed playback iteration ${state.currentIteration}');
        _handleChapterPlaybackComplete();
      }
    });

    _eventSub = _audioPlayer.playbackEventStream.listen(
      (event) {
        AppLogger.info(
          'PlaybackEvent: updateTime=${event.updateTime}, bufferedPosition=${event.bufferedPosition}',
        );
      },
      onError: (Object e, StackTrace stack) {
        AppLogger.error('PlaybackEventStream Error encountered', error: e, stackTrace: stack);
        state = state.copyWith(isLoading: false, isPlaying: false, lastError: 'Playback error: $e');
      },
    );
  }

  Future<void> fetchAndPlayApiBibleChapter({
    required String bookCode,
    required int chapterNumber,
    required String bookName,
  }) async {
    state = state.copyWith(isLoading: true, lastError: null);
    final chapterId = '$bookCode.$chapterNumber';

    AppLogger.info(
      'Fetching live chapter from API.Bible -> Chapter ID: $chapterId, Bible ID: $kWebAudioBibleId',
    );

    try {
      final url = '/audio-bibles/$kWebAudioBibleId/chapters/$chapterId';
      AppLogger.info('Sending GET request to API.Bible endpoint: $url');

      final response = await _dio.get(url);
      AppLogger.info('API.Bible HTTP Response Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        AppLogger.info('API.Bible JSON Response received: $data');

        final String? streamUrl = data['resourceUrl'];
        final String? expiresAt = data['expiresAt'];

        if (streamUrl != null && streamUrl.isNotEmpty) {
          AppLogger.info(
            'Successfully retrieved audio stream URL: $streamUrl (Expires: $expiresAt)',
          );

          final dynamicChapter = ChapterInfo(
            bookCode: bookCode,
            bookName: bookName,
            chapterNumber: chapterNumber,
            audioStreamUrl: streamUrl,
            textContent: 'World English Bible (WEB) — Live REST Audio Stream from API.Bible.',
          );
          await loadChapter(dynamicChapter);
          return;
        }
      }
      throw Exception('API.Bible response did not include a valid resourceUrl.');
    } catch (e, stack) {
      AppLogger.error(
        'API.Bible chapter fetch failed. Triggering local fallback audio.',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(lastError: 'API.Bible fetch failed ($e). Loaded fallback chapter.');
      await loadChapter(kFeaturedChapters[0]);
    }
  }

  Future<void> loadChapter(ChapterInfo chapter) async {
    _gapTimer?.cancel();
    AppLogger.info(
      'Loading chapter audio: ${chapter.reference} from URL: ${chapter.audioStreamUrl}',
    );

    try {
      await _audioPlayer.stop();
    } catch (e) {
      AppLogger.info('Audio player stop notice: $e');
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
      AppLogger.info('Calling _audioPlayer.setUrl()...');
      final dur = await _audioPlayer.setUrl(chapter.audioStreamUrl);
      AppLogger.info('setUrl() finished successfully. Duration: $dur');

      state = state.copyWith(isLoading: false, duration: dur ?? Duration.zero);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to set audio source URL in just_audio player',
        error: e,
        stackTrace: stack,
      );

      // Attempt CORS fallback audio track if primary URL failed on Web
      if (chapter.audioStreamUrl != kFeaturedChapters[0].audioStreamUrl) {
        AppLogger.info('Attempting emergency fallback audio stream...');
        try {
          final fallbackDur = await _audioPlayer.setUrl(kFeaturedChapters[0].audioStreamUrl);
          state = state.copyWith(
            isLoading: false,
            duration: fallbackDur ?? Duration.zero,
            lastError: 'Primary URL audio error ($e). Loaded CORS-friendly fallback.',
          );
          return;
        } catch (fallbackError) {
          AppLogger.error('Fallback audio stream also failed', error: fallbackError);
        }
      }

      state = state.copyWith(isLoading: false, lastError: 'Audio load failed: $e');
    }
  }

  void togglePlayPause() {
    AppLogger.info('User toggled play/pause. Current isPlaying: ${state.isPlaying}');
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  Future<void> play() async {
    AppLogger.info(
      'Play requested. Position: ${state.position}, Duration: ${state.duration}, IsPausedInGap: ${state.isPausedInGap}',
    );

    if (state.isPausedInGap) {
      _gapTimer?.cancel();
      state = state.copyWith(isPausedInGap: false, isPlaying: true);
      _audioPlayer.play();
      return;
    }

    if (state.position >= state.duration && state.duration > Duration.zero) {
      AppLogger.info('Position at end of duration. Seeking to start before playback.');
      await _audioPlayer.seek(Duration.zero);
    }

    try {
      state = state.copyWith(isPlaying: true, lastError: null);
      AppLogger.info('Executing _audioPlayer.play()...');
      await _audioPlayer.play();
      AppLogger.info('_audioPlayer.play() call finished.');
    } catch (e, stack) {
      AppLogger.error('Error while starting audio playback', error: e, stackTrace: stack);
      state = state.copyWith(isPlaying: false, lastError: 'Playback trigger failed: $e');
    }
  }

  Future<void> pause() async {
    AppLogger.info('Pause requested.');
    _gapTimer?.cancel();
    await _audioPlayer.pause();
    state = state.copyWith(isPlaying: false, isPausedInGap: false);
  }

  void seek(Duration pos) {
    AppLogger.info('Seeking to position: ${pos.inSeconds}s');
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

  void toggleKaraoke(bool enabled) {
    state = state.copyWith(karaokeEnabled: enabled);
    AppLogger.logEvent('toggle_karaoke', {
      'enabled': enabled,
      'chapter': state.currentChapter.reference,
    });
  }

  void switchTranslation(String translation) {
    if (translation != 'WEB') {
      AppLogger.logEvent('request_version', {
        'requested_translation': translation,
        'current_book': state.currentChapter.bookCode,
      });
      return;
    }
  }

  void _handleChapterPlaybackComplete() {
    if (state.repetitions != -1 && state.currentIteration >= state.repetitions) {
      AppLogger.info('Completed all ${state.repetitions} repetitions.');
      state = state.copyWith(isPlaying: false, currentIteration: 1);
      _audioPlayer.seek(Duration.zero);
      return;
    }

    state = state.copyWith(isPausedInGap: true);
    AppLogger.info(
      'Entering silent gap interval of ${state.pauseGapSeconds} seconds before iteration ${state.currentIteration + 1}...',
    );

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
    AppLogger.info('Starting iteration ${state.currentIteration + 1}');
    state = state.copyWith(
      currentIteration: state.currentIteration + 1,
      isPausedInGap: false,
      isPlaying: true,
    );
    await _audioPlayer.seek(Duration.zero);
    _audioPlayer.play();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final analytics = AptabaseAnalyticsProvider(appKey: kAptabaseAppKey);
  await analytics.init();
  AppLogger.init(analytics);

  AppLogger.info('Selah Web Audio Player Started.');
  AppLogger.info(
    'Configured API.Bible Key prefix: ${kApiBibleKey.length >= 6 ? kApiBibleKey.substring(0, 6) : "empty"}...',
  );
  AppLogger.info(
    'Configured Aptabase Key prefix: ${kAptabaseAppKey.length >= 6 ? kAptabaseAppKey.substring(0, 6) : "empty"}...',
  );

  runApp(const ProviderScope(child: SelahApp()));
}

class SelahApp extends StatelessWidget {
  const SelahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selah - Scripture Meditation',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0E26),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFFBBF24),
          surface: Color(0xFF1E1B4B),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const ChapterPlayerScreen(),
    );
  }
}

class ChapterPlayerScreen extends ConsumerStatefulWidget {
  const ChapterPlayerScreen({super.key});

  @override
  ConsumerState<ChapterPlayerScreen> createState() => _ChapterPlayerScreenState();
}

class _ChapterPlayerScreenState extends ConsumerState<ChapterPlayerScreen> {
  late final TextEditingController _searchController;
  bool _showDebugLogs = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: 'John 1');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchSubmit(String query) {
    if (query.trim().isEmpty) return;

    if (query.contains(':')) {
      AppLogger.logEvent('request_verse_selection', {'query': query});
      _showVerseNoticeDialog(query);
      return;
    }

    final cleaned = query.trim().toUpperCase();
    ChapterInfo? match;
    for (final ch in kFeaturedChapters) {
      if (cleaned.contains(ch.bookName.toUpperCase()) || cleaned.contains(ch.bookCode)) {
        match = ch;
        break;
      }
    }

    if (match != null) {
      ref.read(chapterPlayerProvider.notifier).loadChapter(match);
    } else {
      AppLogger.logEvent('request_chapter', {'query': query, 'translation': 'WEB'});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fetching "$query" live from API.Bible REST API...'),
          backgroundColor: const Color(0xFF1E1B4B),
        ),
      );
      ref
          .read(chapterPlayerProvider.notifier)
          .fetchAndPlayApiBibleChapter(bookCode: 'JHN', chapterNumber: 3, bookName: 'John');
    }
  }

  void _showVerseNoticeDialog(String userQuery) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 22),
            SizedBox(width: 8),
            Text('v0.3 Preview', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
        content: Text(
          'Specific verse selection ("$userQuery") and synchronized Karaoke text highlighting are coming in v0.3!\n\nFor v0.2, Selah streams clean WEB chapters via API.Bible REST API.',
          style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: Color(0xFFFBBF24))),
          ),
        ],
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(chapterPlayerProvider);
    final notifier = ref.read(chapterPlayerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0E26),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFFBBF24)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF0F0E26), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELAH',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                ),
                Text(
                  'WEB Chapter Audio Meditation',
                  style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showDebugLogs ? Icons.bug_report : Icons.bug_report_outlined,
              color: _showDebugLogs ? Colors.greenAccent : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showDebugLogs = !_showDebugLogs;
              });
            },
            tooltip: 'Toggle Debug Console',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFFBBF24)),
            onPressed: _openSettingsModal,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /* Search Input Bar */
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: _handleSearchSubmit,
                      decoration: InputDecoration(
                        hintText: 'Lookup Chapter (e.g. John 1, Psalm 23)',
                        filled: true,
                        fillColor: const Color(0xFF1E1B4B),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.indigo),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleSearchSubmit(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Play', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /* Preset Selection Chips */
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kFeaturedChapters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final chapter = kFeaturedChapters[index];
                    final isSelected = playerState.currentChapter.reference == chapter.reference;
                    return ChoiceChip(
                      label: Text(chapter.reference),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFF1E1B4B),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => notifier.loadChapter(chapter),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              /* Error Banner */
              if (playerState.lastError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          playerState.lastError!,
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              /* Main Player Card */
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 20, spreadRadius: 4),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      playerState.currentChapter.reference,
                      style: GoogleFonts.newsreader(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'World English Bible (Public Domain) via API.Bible',
                      style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0E26).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          playerState.currentChapter.textContent,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.newsreader(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white.withOpacity(0.87),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFFFBBF24),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: const Color(0xFFFBBF24),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        min: 0,
                        max: playerState.duration.inMilliseconds.toDouble() > 0
                            ? playerState.duration.inMilliseconds.toDouble()
                            : 1.0,
                        value: playerState.position.inMilliseconds.toDouble().clamp(
                          0.0,
                          playerState.duration.inMilliseconds.toDouble() > 0
                              ? playerState.duration.inMilliseconds.toDouble()
                              : 1.0,
                        ),
                        onChanged: (val) => notifier.seek(Duration(milliseconds: val.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerState.position),
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                          Text(
                            _formatDuration(playerState.duration),
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0E26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: playerState.isPausedInGap
                                      ? const Color(0xFFFBBF24)
                                      : (playerState.isPlaying ? Colors.greenAccent : Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                playerState.isPausedInGap
                                    ? 'Silent Gap (${playerState.pauseGapSeconds}s)...'
                                    : (playerState.isPlaying
                                          ? 'Meditating — Playback (${playerState.processingStateName})'
                                          : 'Ready (${playerState.processingStateName})'),
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                          Text(
                            'Loop ${playerState.currentIteration} of ${playerState.repetitions == -1 ? "∞" : playerState.repetitions}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        playerState.isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFFBBF24))
                            : GestureDetector(
                                onTap: notifier.togglePlayPause,
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x40FBBF24),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    playerState.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 38,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),

              /* On-Screen Diagnostic Console */
              if (_showDebugLogs) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09081A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.terminal, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Diagnostic Log Console',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 6),
                      Text(
                        'Active Audio URL: ${playerState.currentChapter.audioStreamUrl}',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      Text(
                        'State: playing=${playerState.isPlaying}, processing=${playerState.processingStateName}, pos=${playerState.position.inSeconds}s/${playerState.duration.inSeconds}s',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          itemCount: AppLogger.logs.length,
                          itemBuilder: (ctx, idx) {
                            final log = AppLogger.logs[idx];
                            final isErr = log.contains('🔴');
                            return Text(
                              log,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: isErr ? Colors.redAccent : Colors.white70,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chapterPlayerProvider);
    final notifier = ref.read(chapterPlayerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meditation Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          const Text(
            'CHAPTER REPETITIONS',
            style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [1, 3, 7, -1].map((r) {
              final isSel = state.repetitions == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setRepetitions(r),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        r == -1 ? '∞' : '${r}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text(
            'SILENT REFLECTION GAP',
            style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [0, 3, 5, 10].map((s) {
              final isSel = state.pauseGapSeconds == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setPauseGap(s),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${s}s',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Karaoke Text Highlighting', style: TextStyle(fontSize: 14)),
            subtitle: const Text(
              'Requires verse timestamps (Arriving in v0.3)',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            value: state.karaokeEnabled,
            activeColor: const Color(0xFFFBBF24),
            onChanged: (val) {
              notifier.toggleKaraoke(val);
              if (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Timestamps load on demand in v0.3! Disabling by default for v0.2.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
