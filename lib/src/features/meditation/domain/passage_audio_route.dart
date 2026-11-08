/// How Selah should play one passage request.
///
/// Human narration wins whenever it can serve the requested verses.
/// Text-to-speech is only for when no human audio can be attempted.
/// A narrator file for a different verse range is neither played nor replaced
/// with a synthetic voice.
enum PassageAudioDecision {
  /// Crossway passage audio for this exact reference.
  playEsvPassage,

  /// Bundled or streamed narrator audio, clipped to the requested verses.
  playNarratorClip,

  /// Narrator audio that already is the requested passage (whole chapter, or
  /// the curated excerpt file).
  playNarratorChapter,

  /// Show the requested words. Do not speak, and do not play a different range.
  holdUnaligned,

  /// No human narrator can be attempted for this request.
  speakWithTts,
}

/// Facts the routing decision is allowed to see. No I/O.
class PassageAudioSituation {
  const PassageAudioSituation({
    required this.esvMode,
    required this.translationHasNarrator,
    required this.hasBundledChapterAudio,
    required this.hasChapterStream,
    this.esvAudioFailed = false,
    this.requestedStart,
    this.requestedEnd,
    this.curatedStart,
    this.curatedEnd,
    this.clipCoversRequestedRange = false,
  });

  /// ESV is the active passage source. TTS must not run in this mode.
  final bool esvMode;

  /// The ESV MP3 was requested and the player rejected it.
  final bool esvAudioFailed;

  /// This translation has a human narrator for the book (WEB OT is false).
  final bool translationHasNarrator;

  /// A bundled chapter/excerpt file exists, such as `assets/audio/BSB/PSA_62.mp3`.
  final bool hasBundledChapterAudio;

  /// An API.Bible (or other) chapter stream URL was fetched.
  final bool hasChapterStream;

  /// Verse range the listener asked for. Null means the whole chapter.
  final int? requestedStart;
  final int? requestedEnd;

  /// Curated meditation on this chapter, if one exists.
  final int? curatedStart;
  final int? curatedEnd;

  /// Timestamps include both ends of the requested range.
  final bool clipCoversRequestedRange;

  bool get requestsVerseRange =>
      requestedStart != null &&
      requestedEnd != null &&
      requestedEnd! >= requestedStart!;

  /// True when the request is the curated window, or there is no narrower request.
  bool get matchesCuratedExcerpt {
    if (!requestsVerseRange) return true;
    if (curatedStart == null || curatedEnd == null) return false;
    return requestedStart == curatedStart && requestedEnd == curatedEnd;
  }
}

/// Pick one playback route.
///
/// Order:
/// 1. ESV passage audio, or silence if that audio failed. Never TTS.
/// 2. Bundled file of the curated excerpt itself.
/// 3. A clip, when timestamps cover the requested verses.
/// 4. Hold, when human audio exists but would be a different range.
/// 5. TTS only when no human audio can be attempted.
PassageAudioDecision decidePassageAudio(PassageAudioSituation situation) {
  if (situation.esvMode) {
    return situation.esvAudioFailed
        ? PassageAudioDecision.holdUnaligned
        : PassageAudioDecision.playEsvPassage;
  }

  final humanAudio =
      situation.hasBundledChapterAudio || situation.hasChapterStream;

  if (situation.matchesCuratedExcerpt && situation.hasBundledChapterAudio) {
    return situation.requestsVerseRange && situation.clipCoversRequestedRange
        ? PassageAudioDecision.playNarratorClip
        : PassageAudioDecision.playNarratorChapter;
  }

  if (situation.requestsVerseRange &&
      situation.clipCoversRequestedRange &&
      humanAudio) {
    return PassageAudioDecision.playNarratorClip;
  }

  if (situation.requestsVerseRange &&
      !situation.clipCoversRequestedRange &&
      humanAudio) {
    return PassageAudioDecision.holdUnaligned;
  }

  if (!situation.requestsVerseRange && humanAudio) {
    return PassageAudioDecision.playNarratorChapter;
  }

  if (!situation.translationHasNarrator || !humanAudio) {
    return PassageAudioDecision.speakWithTts;
  }

  return PassageAudioDecision.holdUnaligned;
}
