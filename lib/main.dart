/*
  =============================================================================
  SELAH — SCRIPTURE AUDIO MEDITATION APP (RIVERPOD 3.0 + FCBH READY)
  =============================================================================

  RUN THIS BASH COMMAND TO ADD ALL NECESSARY DEPENDENCIES:
  -----------------------------------------------------------------------------
  flutter pub add flutter_riverpod flutter_tts dio google_fonts
  -----------------------------------------------------------------------------
*/

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const ProviderScope(child: SelahApp()));

class SelahApp extends StatelessWidget {
  const SelahApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Selah Audio Meditation',
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
    home: const MeditationHomeScreen(),
  );
}

class ScripturePreset {
  final String key, reference, text;
  final String? humanAudioUrl;
  final double? startSeconds, endSeconds;

  const ScripturePreset(
    this.key,
    this.reference,
    this.text, {
    this.humanAudioUrl,
    this.startSeconds,
    this.endSeconds,
  });
}

// Curated Scripture Presets with Public Domain WEB Audio Stream sources
const kPresetVerses = [
  ScripturePreset(
    'psalm46:10',
    'Psalm 46:10',
    'Be still, and know that I am God. I will be exalted among the nations. I will be exalted in the earth.',
    humanAudioUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps046.mp3',
    startSeconds: 36.5,
    endSeconds: 45.0,
  ),
  ScripturePreset(
    'philippians4:6-7',
    'Philippians 4:6-7',
    'Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God. And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.',
    humanAudioUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Php004.mp3',
    startSeconds: 20.0,
    endSeconds: 33.5,
  ),
  ScripturePreset(
    'psalm23:1-3',
    'Psalm 23:1-3',
    'The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters. He restoreth my soul: he leadeth me in the paths of righteousness for his name\'s sake.',
    humanAudioUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps023.mp3',
    startSeconds: 0.0,
    endSeconds: 21.0,
  ),
  ScripturePreset(
    'joshua1:9',
    'Joshua 1:9',
    'Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the Lord thy God is with thee whithersoever thou goest.',
    humanAudioUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Jos001.mp3',
    startSeconds: 48.0,
    endSeconds: 61.0,
  ),
  ScripturePreset(
    'romans12:2',
    'Romans 12:2',
    'And be not conformed to this world: but be ye transformed by the renewing of your mind, that ye may prove what is that good, and acceptable, and perfect, will of God.',
    humanAudioUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Rom012.mp3',
    startSeconds: 8.5,
    endSeconds: 21.0,
  ),
  ScripturePreset(
    'matthew11:28-30',
    'Matthew 11:28-30',
    'Come unto me, all ye that labour and are heavy laden, and I will give you rest. Take my yoke upon you, and learn of me; for I am meek and lowly in heart: and ye shall find rest unto your souls. For my yoke is easy, and my burden is light.',
    humanAudioUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Mat011.mp3',
    startSeconds: 110.0,
    endSeconds: 129.0,
  ),
];

class MeditationState {
  final ScripturePreset selectedPreset;
  final String currentReference, currentVerseText;
  final bool isLoadingVerse, isPlaying, isPausedInGap;
  final int repetitions, currentIteration, pauseGapSeconds, smartTimerMinutes;
  final int highlightStart, highlightEnd; // For Karaoke-style word highlighting
  final DateTime? sessionStartTime;

  const MeditationState({
    required this.selectedPreset,
    required this.currentReference,
    required this.currentVerseText,
    this.isLoadingVerse = false,
    this.isPlaying = false,
    this.isPausedInGap = false,
    this.repetitions = 3,
    this.currentIteration = 0,
    this.pauseGapSeconds = 4,
    this.smartTimerMinutes = 0,
    this.highlightStart = 0,
    this.highlightEnd = 0,
    this.sessionStartTime,
  });

  MeditationState copyWith({
    ScripturePreset? selectedPreset,
    String? currentReference,
    String? currentVerseText,
    bool? isLoadingVerse,
    bool? isPlaying,
    bool? isPausedInGap,
    int? repetitions,
    int? currentIteration,
    int? pauseGapSeconds,
    int? smartTimerMinutes,
    int? highlightStart,
    int? highlightEnd,
    DateTime? sessionStartTime,
    bool clearStartTime = false,
  }) => MeditationState(
    selectedPreset: selectedPreset ?? this.selectedPreset,
    currentReference: currentReference ?? this.currentReference,
    currentVerseText: currentVerseText ?? this.currentVerseText,
    isLoadingVerse: isLoadingVerse ?? this.isLoadingVerse,
    isPlaying: isPlaying ?? this.isPlaying,
    isPausedInGap: isPausedInGap ?? this.isPausedInGap,
    repetitions: repetitions ?? this.repetitions,
    currentIteration: currentIteration ?? this.currentIteration,
    pauseGapSeconds: pauseGapSeconds ?? this.pauseGapSeconds,
    smartTimerMinutes: smartTimerMinutes ?? this.smartTimerMinutes,
    highlightStart: highlightStart ?? this.highlightStart,
    highlightEnd: highlightEnd ?? this.highlightEnd,
    sessionStartTime: clearStartTime ? null : (sessionStartTime ?? this.sessionStartTime),
  );
}

final stageProvider = StateProvider<String>((ref) => 'poc');
final meditationProvider = NotifierProvider<MeditationNotifier, MeditationState>(
  MeditationNotifier.new,
);

class MeditationNotifier extends Notifier<MeditationState> {
  late final FlutterTts _flutterTts;
  late final Dio _dio;
  Timer? _gapTimer;

  @override
  MeditationState build() {
    _flutterTts = FlutterTts();
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    _initTtsEngine();

    ref.onDispose(() {
      _flutterTts.stop();
      _gapTimer?.cancel();
    });

    return MeditationState(
      selectedPreset: kPresetVerses[0],
      currentReference: kPresetVerses[0].reference,
      currentVerseText: kPresetVerses[0].text,
    );
  }

  Future<void> _initTtsEngine() async {
    await _flutterTts.setLanguage("en-US");
    // Slow down speech speed for calm, peaceful narration (less robotic)
    await _flutterTts.setSpeechRate(0.38);
    await _flutterTts.setPitch(0.95);

    // Karaoke-style word highlighting callback handler
    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (state.isPlaying) {
        state = state.copyWith(highlightStart: start, highlightEnd: end);
      }
    });

    _flutterTts.setCompletionHandler(_onIterationComplete);
    _flutterTts.setErrorHandler((_) => _onIterationComplete());
  }

  Future<void> fetchCustomVerse(String query, void Function(String) showSnackBar) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(isLoadingVerse: true);
    try {
      final response = await _dio.get('https://bible-api.com/${Uri.encodeComponent(query.trim())}');
      if (response.statusCode == 200 && response.data is Map && response.data['text'] != null) {
        final refStr = response.data['reference'] ?? query;
        final verseStr = (response.data['text'] as String).replaceAll('\n', ' ').trim();
        stopMeditation();
        state = state.copyWith(
          currentReference: refStr,
          currentVerseText: verseStr,
          currentIteration: 0,
          highlightStart: 0,
          highlightEnd: 0,
          isLoadingVerse: false,
        );
        showSnackBar("Loaded: $refStr");
        return;
      }
      showSnackBar("Could not fetch verse. Try 'Philippians 4:6' or 'Psalm 23:1'");
    } catch (_) {
      showSnackBar("Using local verse fallback.");
    } finally {
      state = state.copyWith(isLoadingVerse: false);
    }
  }

  void selectPreset(ScripturePreset preset) {
    stopMeditation();
    state = state.copyWith(
      selectedPreset: preset,
      currentReference: preset.reference,
      currentVerseText: preset.text,
      currentIteration: 0,
      highlightStart: 0,
      highlightEnd: 0,
    );
  }

  void togglePlayPause(void Function(String) showSnackBar) =>
      state.isPlaying ? pauseMeditation() : startMeditationSession(showSnackBar);

  void startMeditationSession(void Function(String) showSnackBar) {
    if (state.isPausedInGap) {
      _gapTimer?.cancel();
      state = state.copyWith(isPausedInGap: false);
    }
    final nextIter = (state.repetitions != -1 && state.currentIteration >= state.repetitions)
        ? 0
        : state.currentIteration;
    state = state.copyWith(
      isPlaying: true,
      currentIteration: nextIter,
      sessionStartTime: state.sessionStartTime ?? DateTime.now(),
    );
    _playNextIteration(showSnackBar);
  }

  void pauseMeditation() {
    _flutterTts.stop();
    _gapTimer?.cancel();
    state = state.copyWith(isPlaying: false, isPausedInGap: false);
  }

  void stopMeditation() {
    _flutterTts.stop();
    _gapTimer?.cancel();
    state = state.copyWith(
      isPlaying: false,
      isPausedInGap: false,
      currentIteration: 0,
      highlightStart: 0,
      highlightEnd: 0,
      clearStartTime: true,
    );
  }

  void skipLoop(void Function(String) showSnackBar) {
    _flutterTts.stop();
    _gapTimer?.cancel();
    if (state.isPlaying) _onIterationComplete(showSnackBar: showSnackBar);
  }

  void setRepetitions(int reps) => state = state.copyWith(repetitions: reps, currentIteration: 0);
  void setPauseGap(int seconds) => state = state.copyWith(pauseGapSeconds: seconds);
  void setSmartTimer(int minutes) => state = state.copyWith(smartTimerMinutes: minutes);

  Future<void> _playNextIteration([void Function(String)? showSnackBar]) async {
    if (!state.isPlaying) return;
    if (state.smartTimerMinutes > 0 && state.sessionStartTime != null) {
      if (DateTime.now().difference(state.sessionStartTime!).inMinutes >= state.smartTimerMinutes) {
        showSnackBar?.call("Session finished (${state.smartTimerMinutes} min timer completed)");
        stopMeditation();
        return;
      }
    }
    state = state.copyWith(
      currentIteration: state.currentIteration + 1,
      highlightStart: 0,
      highlightEnd: 0,
    );
    await _flutterTts.speak(state.currentVerseText);
  }

  void _onIterationComplete({void Function(String)? showSnackBar}) {
    if (!state.isPlaying) return;
    if (state.repetitions != -1 && state.currentIteration >= state.repetitions) {
      state = state.copyWith(isPlaying: false, highlightStart: 0, highlightEnd: 0);
      showSnackBar?.call("Meditation loop completed 🙏");
      return;
    }
    state = state.copyWith(isPausedInGap: true, highlightStart: 0, highlightEnd: 0);
    _gapTimer = Timer(Duration(seconds: state.pauseGapSeconds), () {
      if (state.isPlaying) {
        state = state.copyWith(isPausedInGap: false);
        _playNextIteration(showSnackBar);
      }
    });
  }
}

class MeditationHomeScreen extends ConsumerStatefulWidget {
  const MeditationHomeScreen({super.key});

  @override
  ConsumerState<MeditationHomeScreen> createState() => _MeditationHomeScreenState();
}

class _MeditationHomeScreenState extends ConsumerState<MeditationHomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: 'John 14:27');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg) => mounted
      ? ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontSize: 13, color: Colors.white)),
            backgroundColor: const Color(0xFF1E1B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        )
      : null;

  @override
  Widget build(BuildContext context) {
    final currentStage = ref.watch(stageProvider);
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
              child: const Icon(Icons.volume_up_rounded, color: Color(0xFF0F0E26), size: 20),
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
                  'Scripture Meditation & Karaoke Sync',
                  style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StageSelectorHeader(),
              const SizedBox(height: 16),
              currentStage == 'plan'
                  ? const ArchitecturePlanView()
                  : PrototypePlayerView(
                      onShowSnackBar: _showSnackBar,
                      searchController: _searchController,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class StageSelectorHeader extends ConsumerWidget {
  const StageSelectorHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1B4B).withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.indigo.withOpacity(0.3)),
    ),
    child: const Row(
      children: [
        StageButton(label: 'Pre-POC', stageKey: 'prepoc'),
        StageButton(label: 'POC', stageKey: 'poc'),
        StageButton(label: 'MVP', stageKey: 'mvp'),
        StageButton(label: 'Plan', stageKey: 'plan', isGold: true),
      ],
    ),
  );
}

class StageButton extends ConsumerWidget {
  final String label, stageKey;
  final bool isGold;
  const StageButton({super.key, required this.label, required this.stageKey, this.isGold = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(stageProvider) == stageKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(meditationProvider.notifier).stopMeditation();
          ref.read(stageProvider.notifier).state = stageKey;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isGold ? const Color(0xFFFBBF24) : const Color(0xFF6366F1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isGold ? Colors.black : Colors.white)
                    : (isGold ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrototypePlayerView extends ConsumerWidget {
  final void Function(String) onShowSnackBar;
  final TextEditingController searchController;

  const PrototypePlayerView({
    super.key,
    required this.onShowSnackBar,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStage = ref.watch(stageProvider);
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B).withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade800.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(switch (currentStage) {
                    'prepoc' => 'Pre-POC: Psalm 46:10 preloaded. Zero input friction.',
                    'poc' =>
                      'POC: Curated scripture presets with 3x repetition loop & reflection gaps.',
                    _ => 'MVP: Fetch any verse via Dio & Bible API (World English Bible) with custom repetitions.',
                  }, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (currentStage == 'mvp') ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Philippians 4:6-7, Psalm 23:1',
                      filled: true,
                      fillColor: const Color(0xFF0F0E26),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.indigo.shade700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => notifier.fetchCustomVerse(searchController.text, onShowSnackBar),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: const Icon(Icons.search, size: 18, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (currentStage == 'poc' || currentStage == 'mvp') ...[
            DropdownButtonFormField<ScripturePreset>(
              value: state.selectedPreset,
              dropdownColor: const Color(0xFF0F0E26),
              style: const TextStyle(fontSize: 13, color: Color(0xFFFBBF24)),
              decoration: InputDecoration(
                labelText: 'Select Meditative Verse Preset',
                labelStyle: TextStyle(fontSize: 12, color: Colors.indigo.shade200),
                filled: true,
                fillColor: const Color(0xFF0F0E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: kPresetVerses
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.reference, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (p) => p != null ? notifier.selectPreset(p) : null,
            ),
            const SizedBox(height: 16),
          ],

          /* Karaoke-Style Scripture Word Highlight Box */
          Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0E26).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.shade900),
            ),
            child: state.isLoadingVerse
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFBBF24)))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.currentReference,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFBBF24),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      KaraokeVerseText(
                        fullText: state.currentVerseText,
                        startOffset: state.highlightStart,
                        endOffset: state.highlightEnd,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          const LoopSettingsGrid(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        color: state.isPausedInGap
                            ? const Color(0xFFFBBF24)
                            : (state.isPlaying ? Colors.greenAccent : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isPausedInGap
                          ? 'Silent Reflection Gap (${state.pauseGapSeconds}s)...'
                          : (state.isPlaying
                                ? 'Meditating — Loop ${state.currentIteration}'
                                : 'Ready to Meditate'),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                Text(
                  'Loop ${state.currentIteration} of ${state.repetitions == -1 ? "∞" : state.repetitions}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.indigo.shade200,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: notifier.stopMeditation,
                icon: const Icon(Icons.stop_rounded, color: Colors.redAccent),
                iconSize: 28,
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => notifier.togglePlayPause(onShowSnackBar),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                    boxShadow: [
                      BoxShadow(color: Color(0x40FBBF24), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 36,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => notifier.skipLoop(onShowSnackBar),
                icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFFBBF24)),
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KaraokeVerseText extends StatelessWidget {
  final String fullText;
  final int startOffset, endOffset;

  const KaraokeVerseText({
    super.key,
    required this.fullText,
    required this.startOffset,
    required this.endOffset,
  });

  @override
  Widget build(BuildContext context) {
    if (startOffset <= 0 && endOffset <= 0) {
      return Text(
        '"$fullText"',
        textAlign: TextAlign.center,
        style: GoogleFonts.newsreader(
          fontSize: 17,
          fontStyle: FontStyle.italic,
          height: 1.4,
          color: Colors.white,
        ),
      );
    }

    final safeStart = startOffset.clamp(0, fullText.length);
    final safeEnd = endOffset.clamp(safeStart, fullText.length);

    final beforeText = fullText.substring(0, safeStart);
    final highlightedWord = fullText.substring(safeStart, safeEnd);
    final afterText = fullText.substring(safeEnd);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.newsreader(
          fontSize: 17,
          fontStyle: FontStyle.italic,
          height: 1.4,
          color: Colors.white70,
        ),
        children: [
          const TextSpan(text: '"'),
          TextSpan(text: beforeText),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFBBF24), width: 1),
              ),
              child: Text(
                highlightedWord,
                style: GoogleFonts.newsreader(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFFBBF24),
                ),
              ),
            ),
          ),
          TextSpan(text: afterText),
          const TextSpan(text: '"'),
        ],
      ),
    );
  }
}

class LoopSettingsGrid extends ConsumerWidget {
  const LoopSettingsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationProvider);
    final notifier = ref.read(meditationProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REPETITIONS',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [1, 3, 7, -1].map((r) {
                    final isSel = state.repetitions == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => notifier.setRepetitions(r),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF6366F1) : const Color(0xFF0F0E26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              r == -1 ? '∞' : '${r}x',
                              style: TextStyle(
                                fontSize: 11,
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
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAUSE BETWEEN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButton<int>(
                  value: state.pauseGapSeconds,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F0E26),
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('2s Pause')),
                    DropdownMenuItem(value: 4, child: Text('4s (Default)')),
                    DropdownMenuItem(value: 7, child: Text('7s (Selah)')),
                    DropdownMenuItem(value: 12, child: Text('12s Deep')),
                  ],
                  onChanged: (val) => val != null ? notifier.setPauseGap(val) : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ArchitecturePlanView extends StatelessWidget {
  const ArchitecturePlanView({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1B4B).withOpacity(0.7),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scripture Meditation Flutter Roadmap',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
        ),
        const SizedBox(height: 4),
        Text(
          'Evolutionary architecture powered by Riverpod 3.0 state management.',
          style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
        ),
        const SizedBox(height: 16),
        const PlanPhaseCard(
          'Pre-POC & POC',
          'Zero Input Friction',
          'Psalm 46:10 preloaded, 3x audio repetition loop, World English Bible Public Domain API.',
        ),
        const PlanPhaseCard(
          'MVP (Current)',
          'Riverpod + Dio Lookup',
          'Fetch any verse via Dio (e.g. John 14:27), cached speech playback, reactive controls.',
        ),
        const PlanPhaseCard(
          'Version 1.1',
          'Continuous Audio & Ambient',
          'Smart continuous session timer (never stops mid-verse), layered background rain/pad audio.',
        ),
        const PlanPhaseCard(
          'Version 2.0',
          'FCBH Bible Brain API Integration',
          'Faith Comes By Hearing API with dramatized audio and millisecond karaoke timestamp sync.',
        ),
      ],
    ),
  );
}

class PlanPhaseCard extends StatelessWidget {
  final String title, subtitle, desc;
  const PlanPhaseCard(this.title, this.subtitle, this.desc, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0F0E26),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.indigo.shade900),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6366F1),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ],
    ),
  );
}

/*
  =============================================================================
  FAITH COMES BY HEARING (FCBH) BIBLE BRAIN API (DBP v4) INTEGRATION GUIDE
  =============================================================================

  Faith Comes By Hearing provides a completely free API called "Bible Brain"
  (Digital Bible Platform v4 at https://4.dbt.io or https://api.biblebrain.com)
  which offers human audio recordings in 1,400+ languages alongside verse timing metadata.

  1. REGISTRATION & API KEY:
     - Register for a free API key at: https://www.faithcomesbyhearing.com or https://biblebrain.com
     - Your key gives access to dramatized audio filesets and alignment timing data.

  2. FETCHING AUDIO FILESETS & CHAPTER MP3s:
     - Endpoint: GET https://4.dbt.io/api/bibles/filesets?v=4&key=YOUR_API_KEY
     - Fetch chapter audio URL:
       GET https://4.dbt.io/api/bibles/filesets/{fileset_id}/{book_id}/{chapter}?v=4&key=YOUR_API_KEY

  3. FETCHING TIMESTAMPS FOR KARAOKE VERSE / WORD HIGHLIGHTING:
     - Endpoint: GET https://4.dbt.io/api/timestamps/{fileset_id}/{book_id}/{chapter}?v=4&key=YOUR_API_KEY
     - Returns JSON array of verse timestamps:
       [
         {"verse_start": "1", "timestamp": 0.0},
         {"verse_start": "2", "timestamp": 4.82},
         {"verse_start": "3", "timestamp": 12.35}
       ]

  4. FLUTTER AUDIO + TIMESTAMP SYNC CODE PATTERN:
     - Use `just_audio` package to listen to audio position streams:
       _audioPlayer.positionStream.listen((position) {
         final currentSeconds = position.inMilliseconds / 1000.0;
         final currentVerse = timestamps.lastWhere(
           (t) => currentSeconds >= t.timestamp,
           orElse: () => timestamps.first,
         );
         // Update State to trigger highlight on currentVerse.verseNumber!
       });
  =============================================================================
*/
