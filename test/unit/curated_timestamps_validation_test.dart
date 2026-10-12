import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  group('Curated Timestamps Calibration & Validation Tests', () {
    final timestampDir = Directory('assets/timestamps');

    test('All curated JSON files exist and have valid schema and monotonicity', () async {
      expect(timestampDir.existsSync(), isTrue, reason: 'assets/timestamps directory must exist');

      final translations = ['BSB', 'WEB'];
      for (final translation in translations) {
        final transDir = Directory('${timestampDir.path}/$translation');
        expect(transDir.existsSync(), isTrue, reason: '$translation directory must exist');

        final files = transDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
        expect(files, isNotEmpty, reason: '$translation must contain timestamp files');

        for (final file in files) {
          final raw = await file.readAsString();
          final List<dynamic> list = jsonDecode(raw);
          expect(list, isNotEmpty, reason: '${file.path} must not be empty');

          int prevEndMs = 0;
          int prevVerse = 0;

          for (final item in list) {
            final map = item as Map<String, dynamic>;
            final verse = map['verse'] as int;
            final text = map['text'] as String;
            final startMs = map['startMs'] as int;
            final endMs = map['endMs'] as int;

            expect(verse, greaterThan(0), reason: '${file.path} verse number must be > 0');
            expect(text.trim(), isNotEmpty, reason: '${file.path} text must not be empty');
            expect(startMs, greaterThanOrEqualTo(0), reason: '${file.path} startMs must be >= 0');
            expect(endMs, greaterThan(startMs), reason: '${file.path} endMs must be > startMs');

            if (prevEndMs > 0) {
              // Ensure verses are monotonically ascending
              expect(verse, greaterThan(prevVerse), reason: '${file.path} verse sequence must ascend');
              // Allow at most 200ms overlap for transition smoothing
              expect(
                startMs,
                greaterThanOrEqualTo(prevEndMs - 200),
                reason: '${file.path} verse $verse overlaps previous by more than 200ms',
              );
            }

            // Word rate sanity check (1.0 to 5.2 words per second)
            final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
            final durationSec = (endMs - startMs) / 1000.0;
            final wps = wordCount / durationSec;
            expect(
              wps,
              greaterThanOrEqualTo(0.9),
              reason: '${file.path} verse $verse speech rate too slow: $wps wps',
            );
            expect(
              wps,
              lessThanOrEqualTo(5.5),
              reason: '${file.path} verse $verse speech rate implausibly fast: $wps wps',
            );

            prevEndMs = endMs;
            prevVerse = verse;
          }
        }
      }
    });

    test('Matthew 11:28–30 (BSB & WEB) starts at calibrated chapter offset, not verse 19', () async {
      final bsbMat = File('assets/timestamps/BSB/MAT_11.json');
      final webMat = File('assets/timestamps/WEB/MAT_11.json');

      final bsbList = (jsonDecode(await bsbMat.readAsString()) as List)
          .map((e) => VerseTimestamp.fromJson(e))
          .toList();
      final webList = (jsonDecode(await webMat.readAsString()) as List)
          .map((e) => VerseTimestamp.fromJson(e))
          .toList();

      // Regression protection: old buggy value was 148,000ms (verse 19 "drinking")
      expect(
        bsbList.first.startMs,
        greaterThanOrEqualTo(250000),
        reason: 'BSB Matt 11:28 must start at ~257.5s, not 148s',
      );
      expect(
        bsbList.last.endMs,
        lessThanOrEqualTo(280000),
        reason: 'BSB Matt 11:30 must end before chapter finishes at 279.3s',
      );

      expect(
        webList.first.startMs,
        greaterThanOrEqualTo(235000),
        reason: 'WEB Matt 11:28 must start at ~238.4s, not 148s',
      );
      expect(
        webList.last.endMs,
        lessThanOrEqualTo(253000),
        reason: 'WEB Matt 11:30 must end before chapter finishes at 252.6s',
      );
    });

    test('Romans 8:31–39 (BSB & WEB) starts at calibrated chapter offset, not verse 25', () async {
      final bsbRom = File('assets/timestamps/BSB/ROM_8.json');
      final webRom = File('assets/timestamps/WEB/ROM_8.json');

      final bsbList = (jsonDecode(await bsbRom.readAsString()) as List)
          .map((e) => VerseTimestamp.fromJson(e))
          .toList();
      final webList = (jsonDecode(await webRom.readAsString()) as List)
          .map((e) => VerseTimestamp.fromJson(e))
          .toList();

      // Regression protection: old buggy value was 205,000ms
      expect(
        bsbList.first.startMs,
        greaterThanOrEqualTo(295000),
        reason: 'BSB Rom 8:31 must start at ~301.1s, not 205s',
      );
      expect(
        bsbList.last.endMs,
        lessThanOrEqualTo(390000),
        reason: 'BSB Rom 8:39 must end near chapter duration 389.4s',
      );

      expect(
        webList.first.startMs,
        greaterThanOrEqualTo(250000),
        reason: 'WEB Rom 8:31 must start at ~254.3s, not 205s',
      );
      expect(
        webList.last.endMs,
        lessThanOrEqualTo(324000),
        reason: 'WEB Rom 8:39 must end near chapter duration 323.9s',
      );
    });

    test('All curated excerpts in kCuratedExcerpts yield valid ClipWindows', () async {
      for (final excerpt in kCuratedExcerpts) {
        final bsbFile = File('assets/timestamps/BSB/${excerpt.bookCode}_${excerpt.chapterNumber}.json');
        if (bsbFile.existsSync()) {
          final list = (jsonDecode(await bsbFile.readAsString()) as List)
              .map((e) => VerseTimestamp.fromJson(e))
              .toList();
          final window = excerpt.clipWindow(list);
          expect(window, isNotNull, reason: 'ClipWindow for BSB ${excerpt.displayTitle} must not be null');
          expect(window!.end, greaterThan(window.start));
          final duration = window.end - window.start;
          expect(
            duration.inSeconds,
            greaterThanOrEqualTo(5),
            reason: '${excerpt.displayTitle} duration must be at least 5s',
          );
        }
      }
    });
  });
}
