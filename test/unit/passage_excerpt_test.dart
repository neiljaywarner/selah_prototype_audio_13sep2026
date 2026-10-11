import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

List<VerseTimestamp> _load(String path) => (jsonDecode(File(path).readAsStringSync()) as List)
    .map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>))
    .toList();

void main() {
  group('PassageExcerpt', () {
    test('1 Corinthians 13 is curated as verses 4-7', () {
      final excerpt = PassageExcerpt.forChapter('1co', 13);
      expect(excerpt, isNotNull);
      expect(excerpt!.startVerse, 4);
      expect(excerpt.endVerse, 7);
    });

    test('Other chapters play in full', () {
      expect(PassageExcerpt.forChapter('1CO', 12), isNull);
      expect(PassageExcerpt.forChapter('JHN', 1), isNull);
    });

    test('BSB clip window starts at v4 (39.6s) and ends at v7 (72.5s)', () {
      final window = PassageExcerpt.forChapter('1CO', 13)!.clipWindow(_load('assets/timestamps/BSB/1CO_13.json'));
      expect(window, isNotNull);
      expect(window!.start, const Duration(milliseconds: 39600));
      expect(window.end, const Duration(milliseconds: 72500));
    });

    test('WEB clip window uses its own v7 end boundary', () {
      final window = PassageExcerpt.forChapter('1CO', 13)!.clipWindow(_load('assets/timestamps/WEB/1CO_13.json'));
      expect(window!.start, const Duration(milliseconds: 39600));
      expect(window.end, const Duration(milliseconds: 61600));
    });

    test('Ignores verses outside the excerpt range', () {
      const excerpt = PassageExcerpt(bookCode: '1CO', chapterNumber: 13, startVerse: 4, endVerse: 7);
      final window = excerpt.clipWindow(const [
        VerseTimestamp(verse: 3, text: 'v3', startMs: 30000, endMs: 39600),
        VerseTimestamp(verse: 4, text: 'v4', startMs: 39600, endMs: 48700),
        VerseTimestamp(verse: 7, text: 'v7', startMs: 63700, endMs: 72500),
        VerseTimestamp(verse: 8, text: 'v8', startMs: 72500, endMs: 80000),
      ]);
      expect(window!.start, const Duration(milliseconds: 39600));
      expect(window.end, const Duration(milliseconds: 72500));
    });

    test('Returns null when timestamps are missing or malformed', () {
      const excerpt = PassageExcerpt(bookCode: '1CO', chapterNumber: 13, startVerse: 4, endVerse: 7);
      expect(excerpt.clipWindow(null), isNull);
      expect(excerpt.clipWindow(const []), isNull);
      expect(
        excerpt.clipWindow(const [VerseTimestamp(verse: 4, text: 'x', startMs: 5000, endMs: 5000)]),
        isNull,
      );
    });
  });
}
