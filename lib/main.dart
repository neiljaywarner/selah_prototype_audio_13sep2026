import 'dart:async';

import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

// =============================================================================
// HOW TO USE --dart-define IN PUBLIC DEPLOYMENT ENVIRONMENTS
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
//    flutter build web --release \
//      --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
//      --dart-define=APTABASE_KEY=$APTABASE_KEY
// =============================================================================

const String kApiBibleBaseUrl = 'https://rest.api.bible/v1';

// Default values redacted for public repository safety
const String kApiBibleKey = String.fromEnvironment('API_BIBLE_KEY', defaultValue: 'REDACTED');
const String kAptabaseAppKey = String.fromEnvironment('APTABASE_KEY', defaultValue: 'REDACTED');

// Verified working Audio Bible ID on API.Bible
const String kWebAudioBibleId = 'aadc8a2f4bdb467b-01'; // World English Bible Audio ID
const String kWebTextBibleId = '986526432f426da3-01'; // World English Bible Text ID

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
    bookCode: 'COL',
    bookName: 'Colossians',
    chapterNumber: 1,
    audioStreamUrl: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=ambient-piano-10781.mp3',
    textContent: 'Paul, an apostle of Christ Jesus through the will of God, and Timothy our brother, to the saints and faithful brothers in Christ at Colossae: Grace to you and peace from God our Father...',
  ),
  const ChapterInfo(
    bookCode: 'JHN',
    bookName: 'John',
    chapterNumber: 1,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Jhn001.mp3',
    textContent: 'In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made through him...',
  ),
  const ChapterInfo(
    bookCode: 'PSL',
    bookName: 'Psalm',
    chapterNumber: 23,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps023.mp3',
    textContent: 'Yahweh is my shepherd: I shall have no lack. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul...',
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
    if (appKey == 'REDACTED' || appKey.isEmpty) {
      debugPrint(
        '⚠️ [APTABASE]: Key is REDACTED. Analytics tracking disabled for dev/public build.',
      );
      return;
    }
    try {
      await Aptabase.init(appKey);
      debugPrint(
        '⚡ [APTABASE]: Analytics initialized successfully with key prefix ${appKey.substring(0, 7)}',
      );
    } catch (e) {
      debugPrint('🔴 [APTABASE INIT ERROR]: $e');
    }
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (appKey == 'REDACTED' || appKey.isEmpty) return;
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
    if (appKey == 'REDACTED' || appKey.isEmpty) return;
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
    if (_inMemoryLogs.length > 60) _inMemoryLogs.removeLast();
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
    if (_inMemoryLogs.length > 60) _inMemoryLogs.removeLast();

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
  final int repetitions;
  final int currentIteration;
  final int pauseGapSeconds;
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
    final url = '/audio-bibles/$kWebAudioBibleId/chapters/$chapterId';

    AppLogger.info(
      'curl "$kApiBibleBaseUrl$url" --header "Accept: application/json" --header "api-key: ${kApiBibleKey.length >= 6 ? kApiBibleKey.substring(0, 6) : "REDACTED"}..."',
    );

    try {
      final response = await _dio.get(url);
      AppLogger.info('API.Bible HTTP Response: Status ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        AppLogger.info('API.Bible Data: $data');

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
                'World English Bible (WEB) — Live REST Audio Stream from API.Bible ($chapterId).',
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

      // Auto-start playback on successful URL set
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final analytics = AptabaseAnalyticsProvider(appKey: kAptabaseAppKey);
  await analytics.init();
  AppLogger.init(analytics);

  AppLogger.info('Selah Web Audio Player Started.');
  AppLogger.info(
    'API.Bible Key status: ${kApiBibleKey == "REDACTED" ? "REDACTED (Set via --dart-define)" : "CONFIGURED"}',
  );
  AppLogger.info(
    'Aptabase Key status: ${kAptabaseAppKey == "REDACTED" ? "REDACTED (Set via --dart-define)" : "CONFIGURED"}',
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
    _searchController = TextEditingController(text: 'COL.1');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /* Helper map to convert book names or abbreviations to standard 3-letter Bible codes */
  static const Map<String, String> _bookCodeMap = {
    'GEN': 'GEN',
    'GENESIS': 'GEN',
    'EXO': 'EXO',
    'EXODUS': 'EXO',
    'PSL': 'PSL',
    'PSA': 'PSL',
    'PSALM': 'PSL',
    'PSALMS': 'PSL',
    'JHN': 'JHN',
    'JOHN': 'JHN',
    'COL': 'COL',
    'COLOSSIANS': 'COL',
    'ROM': 'ROM',
    'ROMANS': 'ROM',
    'MRK': 'MRK',
    'MARK': 'MRK',
    'MAT': 'MAT',
    'MATTHEW': 'MAT',
    'LUK': 'LUK',
    'LUKE': 'LUK',
    'ACT': 'ACT',
    'ACTS': 'ACT',
    'REV': 'REV',
    'REVELATION': 'REV',
  };

  void _handleSearchSubmit(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return;

    if (raw.contains(':')) {
      AppLogger.logEvent('request_verse_selection', {'query': raw});
      _showVerseNoticeDialog(raw);
      return;
    }

    // Check featured presets first
    final cleaned = raw.toUpperCase();
    for (final ch in kFeaturedChapters) {
      if (cleaned == ch.reference.toUpperCase() ||
          cleaned == '${ch.bookCode}.${ch.chapterNumber}') {
        ref.read(chapterPlayerProvider.notifier).loadChapter(ch);
        return;
      }
    }

    // Parse query into book code and chapter number (e.g., COL.1, COL 1, Colossians 1)
    String bookCode = 'COL';
    int chapterNumber = 1;
    String bookName = 'Colossians';

    final normalized = raw.replaceAll('.', ' ').trim();
    final parts = normalized.split(RegExp(r'\s+'));

    if (parts.isNotEmpty) {
      final possibleBook = parts[0].toUpperCase();
      bookCode =
          _bookCodeMap[possibleBook] ??
          (possibleBook.length >= 3 ? possibleBook.substring(0, 3) : 'COL');
      bookName = possibleBook[0] + possibleBook.substring(1).toLowerCase();
    }

    if (parts.length >= 2) {
      chapterNumber = int.tryParse(parts[1]) ?? 1;
    }

    AppLogger.logEvent('request_chapter', {
      'query': raw,
      'parsed_code': bookCode,
      'chapter': chapterNumber,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fetching "$bookCode $chapterNumber" live from API.Bible...'),
        backgroundColor: const Color(0xFF1E1B4B),
        duration: const Duration(seconds: 2),
      ),
    );

    ref
        .read(chapterPlayerProvider.notifier)
        .fetchAndPlayApiBibleChapter(
          bookCode: bookCode,
          chapterNumber: chapterNumber,
          bookName: bookName,
        );
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
          'Specific verse selection ("$userQuery") and synchronized Karaoke text highlighting arrive in v0.3!\n\nFor v0.2, Selah streams complete WEB chapters via API.Bible REST API.',
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
              /* Search Bar */
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: _handleSearchSubmit,
                      decoration: InputDecoration(
                        hintText: 'Lookup Chapter (e.g. COL.1, John 1, Psalm 23)',
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

              /* Error Notification Banner */
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

              /* Main Player Display Card */
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
                                          ? 'Meditating (${playerState.processingStateName})'
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

              /* Live Diagnostic Log Console */
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
                            'Diagnostic Console',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 4),
                      Text(
                        'Target Bible ID: $kWebAudioBibleId',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      Text(
                        'Audio Stream: ${playerState.currentChapter.audioStreamUrl}',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
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
              'Requires verse timestamps (v0.3 feature)',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            value: state.karaokeEnabled,
            activeColor: const Color(0xFFFBBF24),
            onChanged: (val) {
              notifier.toggleKaraoke(val);
            },
          ),
        ],
      ),
    );
  }
}
