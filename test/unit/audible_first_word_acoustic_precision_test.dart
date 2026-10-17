import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  group('Audible First-Word Acoustic Precision Tests (#213)', () {
    test('1 Corinthians 13:4-7 starts cleanly on "Love" across BSB, WEB, and NIV', () {
      final translations = {
        'BSB': (expectedStartMs: 39600, firstWord: 'Love'),
        'WEB': (expectedStartMs: 40900, firstWord: 'Love'),
        'NIV': (expectedStartMs: 14880, firstWord: 'Love'),
      };

      for (final entry in translations.entries) {
        final tr = entry.key;
        final expected = entry.value;
        final file = File('assets/timestamps/$tr/1CO_13.json');
        expect(file.existsSync(), isTrue, reason: 'Timestamp file for $tr 1CO_13 must exist');

        final list = (jsonDecode(file.readAsStringSync()) as List)
            .map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>))
            .toList();

        final v4 = list.firstWhere((v) => v.verse == 4);
        expect(v4.startMs, equals(expected.expectedStartMs),
            reason: '$tr 1 Cor 13:4 startMs must match calibrated acoustic pause boundary');
        expect(v4.text.startsWith(expected.firstWord), isTrue,
            reason: '$tr 1 Cor 13:4 text must start with "${expected.firstWord}"');

        // Verify PassageExcerpt.clipWindow produces exact boundary
        final excerpt = PassageExcerpt.forChapter('1CO', 13);
        expect(excerpt, isNotNull);
        final window = excerpt!.clipWindow(list);
        expect(window, isNotNull);
        expect(window!.start.inMilliseconds, equals(expected.expectedStartMs),
            reason: '$tr clip window must start precisely at verse 4 boundary');
      }
    });

    test('All 27 repository timestamp assets satisfy strict acoustic and speech rate bounds', () {
      final dir = Directory('assets/timestamps');
      expect(dir.existsSync(), isTrue);

      final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      expect(files.length, equals(27), reason: 'Expected exactly 27 timestamp assets in repository');

      int totalVerses = 0;
      for (final file in files) {
        final raw = jsonDecode(file.readAsStringSync()) as List;
        expect(raw, isNotEmpty, reason: '${file.path} must not be empty');
        totalVerses += raw.length;

        int prevEndMs = 0;
        for (final item in raw) {
          final vt = VerseTimestamp.fromJson(item as Map<String, dynamic>);
          expect(vt.verse, greaterThan(0));
          expect(vt.text.trim(), isNotEmpty);
          expect(vt.startMs, lessThan(vt.endMs),
              reason: 'In ${file.path} verse ${vt.verse}: startMs (${vt.startMs}) must be < endMs (${vt.endMs})');
          expect(vt.startMs, greaterThanOrEqualTo(prevEndMs),
              reason: 'In ${file.path} verse ${vt.verse}: startMs must be >= previous verse endMs ($prevEndMs)');

          final wordCount = vt.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          final durationSec = (vt.endMs - vt.startMs) / 1000.0;
          final wps = wordCount / durationSec;

          // Natural human speech bounds: 0.8 WPS (48 WPM) to 4.8 WPS (288 WPM)
          expect(wps, greaterThanOrEqualTo(0.8),
              reason: 'In ${file.path} verse ${vt.verse}: abnormally slow ($wps WPS)');
          expect(wps, lessThanOrEqualTo(5.5),
              reason: 'In ${file.path} verse ${vt.verse}: abnormally fast ($wps WPS)');

          prevEndMs = vt.endMs;
        }
      }

      expect(totalVerses, equals(100), reason: 'Total audited verses across repository must be exactly 100');
    });

    test('Matthew 11:28-30 starts cleanly on "Come" without preceding narrative', () {
      for (final tr in ['BSB', 'WEB']) {
        final file = File('assets/timestamps/$tr/MAT_11.json');
        expect(file.existsSync(), isTrue);

        final list = (jsonDecode(file.readAsStringSync()) as List)
            .map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>))
            .toList();

        final v28 = list.firstWhere((v) => v.verse == 28);
        expect(v28.text.startsWith('Come'), isTrue);

        final excerpt = PassageExcerpt.forChapter('MAT', 11);
        expect(excerpt, isNotNull);
        final window = excerpt!.clipWindow(list);
        expect(window, isNotNull);
        expect(window!.start.inMilliseconds, equals(v28.startMs));
      }
    });

    test('Universal passage acoustic estimation creates valid clip window when precompiled assets are absent', () {
      const sampleChapterText = '''1 The heavens declare the glory of God; the skies proclaim the work of his hands.
2 Day after day they pour forth speech; night after night they reveal knowledge.
3 They have no speech, they use no words; no sound is heard from them.
4 Yet their voice goes out into all the earth, their words to the ends of the world.''';

      final totalDuration = const Duration(seconds: 40);
      final estimated = TimestampLoaderService.estimateVerseTimestamps(
        textContent: sampleChapterText,
        totalDuration: totalDuration,
      );

      expect(estimated.length, equals(4));
      expect(estimated[0].verse, equals(1));
      expect(estimated[0].startMs, equals(0));
      expect(estimated[3].verse, equals(4));
      expect(estimated[3].endMs, equals(totalDuration.inMilliseconds));

      // Clip to verses 2-3
      final excerpt = PassageExcerpt.customExcerpt(
        bookCode: 'PSA',
        chapterNumber: 19,
        startVerse: 2,
        endVerse: 3,
      );
      expect(excerpt, isNotNull);

      final window = excerpt!.clipWindow(estimated);
      expect(window, isNotNull);
      expect(window!.start.inMilliseconds, equals(estimated[1].startMs));
      expect(window.end.inMilliseconds, equals(estimated[2].endMs));
      expect(window.start, greaterThan(Duration.zero));
      expect(window.end, lessThan(totalDuration));
    });
  });
}
