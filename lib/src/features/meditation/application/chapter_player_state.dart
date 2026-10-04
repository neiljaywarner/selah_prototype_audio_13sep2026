import '../domain/chapter_info.dart';

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
    this.activeTranslation = 'BSB',
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
