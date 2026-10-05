import 'dart:convert';

import 'package:flutter/services.dart';

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
    } catch (_) {
      // Return null gracefully if file does not exist (skip highlighting without crashing)
      return null;
    }
  }
}
