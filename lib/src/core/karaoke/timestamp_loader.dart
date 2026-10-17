import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

class VerseTimestamp {
  final int verse;
  final String text;
  final int startMs;
  final int endMs;

  const VerseTimestamp({
    required this.verse,
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  factory VerseTimestamp.fromJson(Map<String, dynamic> json) => VerseTimestamp(
    verse: json['verse'] ?? 0,
    text: json['text'] ?? '',
    startMs: json['startMs'] ?? 0,
    endMs: json['endMs'] ?? 0,
  );
}

class TimestampLoaderService {
  /// Map of chapters to the verse range covered in pre-compiled assets.
  /// If null, the entire chapter is covered.
  static const Map<String, ({int start, int end})?> _knownTimestampRanges = {
    // Level 1: Soft Launch Baseline (6 Curated)
    'MRK_5': null,
    'MAT_11': null,
    'PSA_62': (start: 1, end: 2),
    'PSA_23': null,
    'ROM_8': null,
    '1CO_13': null,
    '1COR_13': null,
    'COL_1': null,

    // Level 2: Top 12 Contemplative Passages (#95)
    'PSA_91': (start: 1, end: 4),
    'JHN_3': (start: 16, end: 17),
    'PHP_4': (start: 4, end: 8),
    'PRO_3': (start: 5, end: 6),
    'ISA_40': (start: 28, end: 31),
    'ROM_12': (start: 1, end: 2),
  };

  /// Returns true if the requested book and chapter have local WhisperX timestamps.
  static bool hasTimestampsFor({
    required String bookCode,
    required int chapterNumber,
  }) {
    final key = '${bookCode.toUpperCase()}_$chapterNumber';
    return _knownTimestampRanges.containsKey(key);
  }

  /// Returns true only if the requested verse range is fully covered by local WhisperX timestamps.
  static bool hasCoverageForRange({
    required String bookCode,
    required int chapterNumber,
    required int startVerse,
    required int endVerse,
  }) {
    final key = '${bookCode.toUpperCase()}_$chapterNumber';
    if (!_knownTimestampRanges.containsKey(key)) return false;
    final range = _knownTimestampRanges[key];
    if (range == null) return true; // Full chapter covered
    return startVerse >= range.start && endVerse <= range.end;
  }

  static Future<List<VerseTimestamp>?> loadChapterTimestamps({
    required String translation,
    required String bookCode,
    required int chapterNumber,
  }) async {
    final assetPath =
        'assets/timestamps/${translation.toUpperCase()}/${bookCode.toUpperCase()}_$chapterNumber.json';
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> rawList = jsonDecode(jsonString);
      return rawList.map((e) => VerseTimestamp.fromJson(e)).toList();
    } catch (e, stack) {
      final errStr = e.toString();
      if (errStr.contains('Unable to load asset') || e is FlutterError) {
        AppLogger.info(
          'WhisperX timestamp asset not present for $translation.$bookCode.$chapterNumber (falling back to standard playback)',
        );
        AppLogger.logEvent('timestamps_missing', {
          'translation': translation,
          'book_code': bookCode,
          'chapter': chapterNumber,
        });
      } else {
        AppLogger.error(
          'Unexpected error loading/parsing WhisperX timestamps for $translation.$bookCode.$chapterNumber',
          error: e,
          stackTrace: stack,
          properties: {
            'translation': translation,
            'book_code': bookCode,
            'chapter': chapterNumber,
            'asset_path': assetPath,
          },
        );
        AppLogger.logEvent('timestamps_load_error', {
          'translation': translation,
          'book_code': bookCode,
          'chapter': chapterNumber,
          'error': errStr,
        });
      }
      return null;
    }
  }

  /// Heuristically generates proportional verse timestamps for arbitrary chapters
  /// across the 66 canonical books when pre-compiled WhisperX assets are not present.
  /// Paced at ~140 words-per-minute with 350ms acoustic breathing pauses between verses.
  static List<VerseTimestamp> estimateVerseTimestamps({
    required String textContent,
    required Duration totalDuration,
  }) {
    if (textContent.trim().isEmpty || totalDuration.inMilliseconds <= 0) {
      return [];
    }

    final rawLines = textContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final verses = <({int verseNum, String text, int wordCount})>[];
    final verseRegex = RegExp(r'^(\d+)[\s.:]+(.*)$');

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      final match = verseRegex.firstMatch(line);
      final int vNum;
      final String vText;
      if (match != null) {
        vNum = int.tryParse(match.group(1) ?? '') ?? (i + 1);
        vText = match.group(2) ?? line;
      } else {
        vNum = i + 1;
        vText = line;
      }
      final words = vText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      verses.add((verseNum: vNum, text: vText, wordCount: words > 0 ? words : 1));
    }

    if (verses.isEmpty) return [];

    final totalWords = verses.fold<int>(0, (sum, v) => sum + v.wordCount);
    final totalMs = totalDuration.inMilliseconds;
    int currentMs = 0;
    const pauseMs = 350;

    final result = <VerseTimestamp>[];
    for (int i = 0; i < verses.length; i++) {
      final v = verses[i];
      final verseShareMs = ((v.wordCount / totalWords) * totalMs).round();
      final startMs = currentMs;
      final endMs = (i == verses.length - 1)
          ? totalMs
          : (currentMs + verseShareMs - pauseMs).clamp(startMs + 500, totalMs);

      result.add(VerseTimestamp(
        verse: v.verseNum,
        text: v.text,
        startMs: startMs,
        endMs: endMs,
      ));

      currentMs = (currentMs + verseShareMs).clamp(0, totalMs);
    }

    return result;
  }
}
