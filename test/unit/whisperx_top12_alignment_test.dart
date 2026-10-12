import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/cache/offline_scripture_cache.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  group('WhisperX Level 2 Alignment & Top 12 Passages (#95)', () {
    test('TimestampLoaderService.hasTimestampsFor recognizes Level 1 and Level 2 chapters', () {
      // Level 1
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'PSA', chapterNumber: 23), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'PSA', chapterNumber: 62), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'MAT', chapterNumber: 11), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: '1CO', chapterNumber: 13), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'COL', chapterNumber: 1), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'MRK', chapterNumber: 5), isTrue);

      // Level 2 (Top 12)
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'PSA', chapterNumber: 91), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'JHN', chapterNumber: 3), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'PHP', chapterNumber: 4), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'PRO', chapterNumber: 3), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'ISA', chapterNumber: 40), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'ROM', chapterNumber: 12), isTrue);

      // Unaligned chapters
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'GEN', chapterNumber: 1), isFalse);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'REV', chapterNumber: 22), isFalse);
    });

    test('All 12 generated Level 2 timestamp asset files exist and have valid monotonic schemas', () {
      final chapters = ['PSA_91', 'JHN_3', 'PHP_4', 'PRO_3', 'ISA_40', 'ROM_12'];
      final translations = ['BSB', 'WEB'];

      for (final tr in translations) {
        for (final ch in chapters) {
          final file = File('assets/timestamps/$tr/$ch.json');
          expect(file.existsSync(), isTrue, reason: 'File assets/timestamps/$tr/$ch.json must exist');

          final rawJson = jsonDecode(file.readAsStringSync()) as List<dynamic>;
          expect(rawJson, isNotEmpty);

          int prevEnd = 0;
          for (final item in rawJson) {
            final vt = VerseTimestamp.fromJson(item as Map<String, dynamic>);
            expect(vt.verse, greaterThan(0));
            expect(vt.text.trim(), isNotEmpty);
            expect(vt.startMs, lessThan(vt.endMs));
            expect(vt.startMs, greaterThanOrEqualTo(prevEnd));
            prevEnd = vt.endMs;
          }
        }
      }
    });

    test('PassageExcerpt.customExcerpt computes accurate clip window for Level 2 verse ranges', () {
      // Mock timestamps for Psalm 91:1-4
      final psalm91Verses = [
        const VerseTimestamp(verse: 1, text: 'He who dwells in the shelter...', startMs: 0, endMs: 4000),
        const VerseTimestamp(verse: 2, text: 'I will say of the LORD...', startMs: 4500, endMs: 8500),
        const VerseTimestamp(verse: 3, text: 'Surely He will deliver you...', startMs: 9000, endMs: 13000),
        const VerseTimestamp(verse: 4, text: 'He will cover you with His feathers...', startMs: 13500, endMs: 18000),
      ];

      final excerpt = PassageExcerpt.customExcerpt(
        bookCode: 'PSA',
        chapterNumber: 91,
        startVerse: 1,
        endVerse: 4,
        displayTitle: 'Psalm 91:1-4',
      );

      expect(excerpt, isNotNull);
      expect(excerpt!.displayTitle, 'Psalm 91:1-4');
      expect(excerpt.startVerse, 1);
      expect(excerpt.endVerse, 4);
      final window = excerpt.clipWindow(psalm91Verses);
      expect(window, isNotNull);
      expect(window!.start, Duration.zero);
      expect(window.end, const Duration(milliseconds: 18000));
    });

    test('OfflineScriptureCache provides instant text for Level 2 public domain passages', () {
      final cache = OfflineScriptureCache(null);

      // Verify BSB Level 2 texts
      expect(cache.hasOfflineText('BSB', 'PSA', 91), isTrue);
      expect(cache.hasOfflineText('BSB', 'JHN', 3), isTrue);
      expect(cache.hasOfflineText('BSB', 'PHP', 4), isTrue);
      expect(cache.hasOfflineText('BSB', 'PRO', 3), isTrue);
      expect(cache.hasOfflineText('BSB', 'ISA', 40), isTrue);
      expect(cache.hasOfflineText('BSB', 'ROM', 12), isTrue);

      // Verify WEB Level 2 texts
      expect(cache.hasOfflineText('WEB', 'PSA', 91), isTrue);
      expect(cache.hasOfflineText('WEB', 'JHN', 3), isTrue);
      expect(cache.hasOfflineText('WEB', 'PHP', 4), isTrue);
      expect(cache.hasOfflineText('WEB', 'PRO', 3), isTrue);
      expect(cache.hasOfflineText('WEB', 'ISA', 40), isTrue);
      expect(cache.hasOfflineText('WEB', 'ROM', 12), isTrue);

      final john3Bsb = cache.getOfflineText('BSB', 'JHN', 3);
      expect(john3Bsb, contains('For God so loved the world'));

      final isaiah40Web = cache.getOfflineText('WEB', 'ISA', 40);
      expect(isaiah40Web, contains('mount up with wings like eagles'));
    });
  });
}
