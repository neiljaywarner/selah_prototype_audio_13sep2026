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

    test('Matthew 11 is curated as verses 28-30', () {
      final excerpt = PassageExcerpt.forChapter('MAT', 11);
      expect(excerpt, isNotNull);
      expect(excerpt!.startVerse, 28);
      expect(excerpt.endVerse, 30);
      expect(excerpt.displayTitle, 'Matt 11:28–30');

      final bsbWindow = excerpt.clipWindow(_load('assets/timestamps/BSB/MAT_11.json'));
      expect(bsbWindow, isNotNull);
      expect(bsbWindow!.start, const Duration(milliseconds: 257570));
      expect(bsbWindow.end, const Duration(milliseconds: 277800));

      final webWindow = excerpt.clipWindow(_load('assets/timestamps/WEB/MAT_11.json'));
      expect(webWindow, isNotNull);
      expect(webWindow!.start, const Duration(milliseconds: 235330));
      expect(webWindow.end, const Duration(milliseconds: 250400));
    });

    test('Romans 8 is curated as verses 31-39', () {
      final excerpt = PassageExcerpt.forChapter('ROM', 8);
      expect(excerpt, isNotNull);
      expect(excerpt!.startVerse, 31);
      expect(excerpt.endVerse, 39);
      expect(excerpt.displayTitle, 'Rom 8:31–39');

      final bsbWindow = excerpt.clipWindow(_load('assets/timestamps/BSB/ROM_8.json'));
      expect(bsbWindow, isNotNull);
      expect(bsbWindow!.start, const Duration(milliseconds: 301150));
      expect(bsbWindow.end, const Duration(milliseconds: 387700));

      final webWindow = excerpt.clipWindow(_load('assets/timestamps/WEB/ROM_8.json'));
      expect(webWindow, isNotNull);
      expect(webWindow!.start, const Duration(milliseconds: 254300));
      expect(webWindow.end, const Duration(milliseconds: 321600));
    });

    test('Psalm 23 is curated as verses 1-6', () {
      final excerpt = PassageExcerpt.forChapter('PSA', 23);
      expect(excerpt, isNotNull);
      expect(excerpt!.startVerse, 1);
      expect(excerpt.endVerse, 6);
      expect(excerpt.displayTitle, 'Psalm 23');

      final bsbWindow = excerpt.clipWindow(_load('assets/timestamps/BSB/PSA_23.json'));
      expect(bsbWindow, isNotNull);
      expect(bsbWindow!.start, Duration.zero);
      expect(bsbWindow.end, const Duration(milliseconds: 41000));

      final webWindow = excerpt.clipWindow(_load('assets/timestamps/WEB/PSA_23.json'));
      expect(webWindow, isNotNull);
      expect(webWindow!.start, Duration.zero);
      expect(webWindow.end, const Duration(milliseconds: 39000));
    });
  });
}
