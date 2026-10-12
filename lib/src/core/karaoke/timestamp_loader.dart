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
  /// Set of chapters with pre-compiled WhisperX verse timestamps in assets/timestamps/
  static const Set<String> _knownTimestampChapters = {
    // Level 1: Soft Launch Baseline (6 Curated)
    'MRK_5',
    'MAT_11',
    'PSA_62',
    'PSA_23',
    'ROM_8',
    '1CO_13',
    '1COR_13',
    'COL_1',

    // Level 2: Top 12 Contemplative Passages (#95)
    'PSA_91',
    'JHN_3',
    'PHP_4',
    'PRO_3',
    'ISA_40',
    'ROM_12',
  };

  /// Returns true if the requested book and chapter have local WhisperX timestamps.
  static bool hasTimestampsFor({
    required String bookCode,
    required int chapterNumber,
  }) {
    final key = '${bookCode.toUpperCase()}_$chapterNumber';
    return _knownTimestampChapters.contains(key);
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
}
