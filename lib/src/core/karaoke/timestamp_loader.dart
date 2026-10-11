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
      }
      return null;
    }
  }
}
