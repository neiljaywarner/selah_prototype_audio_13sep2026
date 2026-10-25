import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/cache/offline_scripture_cache.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/picker/bible_reference_parser.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1 Corinthians 13:4-7 Verse 4 Audio & Text Alignment Tests', () {
    test('Featured preset chapter for 1 Corinthians 13 starts directly at Verse 4', () {
      final corinthiansPreset = kFeaturedChapters.firstWhere(
        (c) => c.bookCode == '1CO' && c.chapterNumber == 13,
      );

      expect(corinthiansPreset, isNotNull);
      expect(corinthiansPreset.bookName, equals('1 Corinthians'));
      expect(corinthiansPreset.chapterNumber, equals(13));

      // Must start directly at Verse 4 ("Love is patient, love is kind"), not Verse 1
      expect(corinthiansPreset.textContent, startsWith('Love is patient, love is kind'));
      expect(corinthiansPreset.textContent.contains('If I speak with tongues'), isFalse);
      expect(corinthiansPreset.textContent.contains('Though I speak'), isFalse);
    });

    test('BSB timestamps file starts at Verse 4 at exactly 39,600ms boundary', () {
      final file = File('assets/timestamps/BSB/1CO_13.json');
      expect(file.existsSync(), isTrue, reason: 'assets/timestamps/BSB/1CO_13.json must exist');

      final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      expect(jsonList, isNotEmpty);

      final timestamps = jsonList.map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>)).toList();

      final firstVerse = timestamps.first;
      expect(firstVerse.verse, equals(4), reason: 'First timestamp must be verse 4');
      expect(firstVerse.startMs, equals(39600), reason: 'Audio starts at 39.6s narrator pause boundary');
      expect(firstVerse.text, startsWith('Love is patient, love is kind'));

      // Check all 4 verses 4..7 exist in order
      expect(timestamps.map((t) => t.verse).toList(), equals([4, 5, 6, 7]));

      // Verify startMs < endMs for each verse
      for (final vt in timestamps) {
        expect(vt.startMs, lessThan(vt.endMs));
      }
    });

    test('WEB timestamps file starts at Verse 4 at calibrated 40,900ms boundary', () {
      final file = File('assets/timestamps/WEB/1CO_13.json');
      expect(file.existsSync(), isTrue, reason: 'assets/timestamps/WEB/1CO_13.json must exist');

      final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      expect(jsonList, isNotEmpty);

      final timestamps = jsonList.map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>)).toList();

      final firstVerse = timestamps.first;
      expect(firstVerse.verse, equals(4));
      expect(firstVerse.startMs, equals(40900), reason: 'WEB audio starts at 40.9s narrator pause boundary');
      expect(firstVerse.text, startsWith('Love is patient, love is kind'));

      expect(timestamps.map((t) => t.verse).toList(), equals([4, 5, 6, 7]));
    });

    test('NIV timestamps file starts at Verse 4 at exactly 14,880ms boundary', () {
      final file = File('assets/timestamps/NIV/1CO_13.json');
      expect(file.existsSync(), isTrue, reason: 'assets/timestamps/NIV/1CO_13.json must exist');

      final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      expect(jsonList, isNotEmpty);

      final timestamps = jsonList.map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>)).toList();

      final firstVerse = timestamps.first;
      expect(firstVerse.verse, equals(4), reason: 'First timestamp must be verse 4');
      expect(firstVerse.startMs, equals(14880), reason: 'Audio starts at 14.88s narrator pause boundary');
      expect(firstVerse.text, startsWith('Love is patient, love is kind'));

      expect(timestamps.map((t) => t.verse).toList(), equals([4, 5, 6, 7]));

      for (final vt in timestamps) {
        expect(vt.startMs, lessThan(vt.endMs));
      }
    });

    test('Audio seek boundary (39,600ms) matches Verse 4 karaoke highlight at character index 0', () {
      final corinthiansPreset = kFeaturedChapters.firstWhere(
        (c) => c.bookCode == '1CO' && c.chapterNumber == 13,
      );

      final file = File('assets/timestamps/BSB/1CO_13.json');
      final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      final timestamps = jsonList.map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>)).toList();

      // Simulate player reaching 39,600ms (where audio player seeks)
      const playerPositionMs = 39600;

      VerseTimestamp? activeVerse;
      for (final vt in timestamps) {
        if (playerPositionMs >= vt.startMs && playerPositionMs < vt.endMs) {
          activeVerse = vt;
          break;
        }
      }

      expect(activeVerse, isNotNull);
      expect(activeVerse!.verse, equals(4));

      // In the chapter text, verse 4 must start at index 0 (opening text)
      final fullText = corinthiansPreset.textContent;
      // Normalizing for whitespace check
      expect(fullText.startsWith('Love is patient, love is kind'), isTrue);

      // Verify that verse 4 text can be located at character index 0
      final idx = fullText.indexOf('Love is patient, love is kind');
      expect(idx, equals(0));
    });

    test('Progressive playback through 1 Cor 13:4-7 highlights each verse sequentially', () {
      final file = File('assets/timestamps/BSB/1CO_13.json');
      final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      final timestamps = jsonList.map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>)).toList();

      // Test position sample in each verse range
      final testCases = [
        {'timeMs': 40000, 'expectedVerse': 4}, // Verse 4 (39600 - 48700)
        {'timeMs': 50000, 'expectedVerse': 5}, // Verse 5 (48700 - 58300)
        {'timeMs': 60000, 'expectedVerse': 6}, // Verse 6 (58300 - 63700)
        {'timeMs': 70000, 'expectedVerse': 7}, // Verse 7 (63700 - 72500)
      ];

      for (final tc in testCases) {
        final pos = tc['timeMs'] as int;
        final expected = tc['expectedVerse'] as int;

        VerseTimestamp? matched;
        for (final vt in timestamps) {
          if (pos >= vt.startMs && pos < vt.endMs) {
            matched = vt;
            break;
          }
        }

        expect(matched, isNotNull, reason: 'Should find verse at $pos ms');
        expect(matched!.verse, equals(expected));
      }
    });

    test('OfflineScriptureCache has BSB and WEB 1CO 13 text starting at verse 4', () {
      final cache = OfflineScriptureCache(null);
      final bsbText = cache.getOfflineText('BSB', '1CO', 13);
      final webText = cache.getOfflineText('WEB', '1CO', 13);

      expect(bsbText, isNotNull);
      expect(bsbText!, startsWith('Love is patient, love is kind'));
      expect(bsbText.contains('Though I speak'), isFalse);
      expect(bsbText.contains('If I speak with the tongues'), isFalse);

      expect(webText, isNotNull);
      expect(webText!, startsWith('Love is patient, love is kind'));
      expect(webText.contains('Though I speak'), isFalse);
      expect(webText.contains('If I speak with the tongues'), isFalse);
    });

    test('BibleReferenceParser resolves "1 Cor 13:4-7", "1Cor 13:4-7", and "1 Corinthians 13:4-7"', () {
      final queries = [
        '1 Cor 13:4-7',
        '1Cor 13:4-7',
        '1 Corinthians 13:4-7',
        '1CO 13:4-7',
        '1 Cor 13',
      ];

      for (final q in queries) {
        final suggestions = BibleReferenceParser.getSuggestions(q);
        expect(suggestions, isNotEmpty, reason: 'Query "$q" must return suggestions');
        final first = suggestions.first;
        expect(first.book.code, equals('1CO'), reason: 'Query "$q" must match 1CO');
        expect(first.chapter, equals(13), reason: 'Query "$q" must match chapter 13');
      }
    });

    test('Playing 1 Cor 13:4-7 for 3 repetitions retains clip boundaries [39.6s, 72.5s] across all 3 loops', () {
      final file = File('assets/timestamps/BSB/1CO_13.json');
      final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      final timestamps = jsonList.map((e) => VerseTimestamp.fromJson(e as Map<String, dynamic>)).toList();

      final excerpt = PassageExcerpt.forChapter('1CO', 13);
      expect(excerpt, isNotNull);

      final window = excerpt!.clipWindow(timestamps);
      expect(window, isNotNull);
      expect(window!.start, const Duration(milliseconds: 39600));
      expect(window.end, const Duration(milliseconds: 72500));

      for (int loop = 1; loop <= 3; loop++) {
        final loopWindow = excerpt.clipWindow(timestamps);
        expect(loopWindow, isNotNull, reason: 'Loop $loop must have valid clip window');
        expect(loopWindow!.start.inMilliseconds, equals(39600), reason: 'Loop $loop must start at 39,600ms (verse 4)');
        expect(loopWindow.end.inMilliseconds, equals(72500), reason: 'Loop $loop must end at 72,500ms (verse 7)');

        // Relative position 0ms in the clip maps to verse 4 (startMs 39600)
        final posAtStartMs = 0 + loopWindow.start.inMilliseconds;
        final vAtStart = timestamps.firstWhere((t) => posAtStartMs >= t.startMs && posAtStartMs < t.endMs);
        expect(vAtStart.verse, equals(4), reason: 'Loop $loop start must highlight verse 4');

        // Relative position at end of clip maps to verse 7 (endMs 72500)
        final posAtEndMs = (loopWindow.end - loopWindow.start).inMilliseconds - 100 + loopWindow.start.inMilliseconds;
        final vAtEnd = timestamps.firstWhere((t) => posAtEndMs >= t.startMs && posAtEndMs <= t.endMs);
        expect(vAtEnd.verse, equals(7), reason: 'Loop $loop end must highlight verse 7');
      }
    });

    test('kFeaturedChapters contains curated demo passages', () {
      expect(kFeaturedChapters.length, equals(5));
      final references = kFeaturedChapters.map((c) => c.reference).toList();
      expect(references, equals(['1 Cor 13:4–7', 'Matt 11:28–30', 'Rom 8:31–39', 'Psalm 23', '1 Peter 5:7–9']));

      // Matthew 11:28-30
      final mat = kFeaturedChapters.firstWhere((c) => c.bookCode == 'MAT');
      expect(mat.textContent, startsWith('Come to Me, all you who are weary'));

      // Romans 8:31-39
      final rom = kFeaturedChapters.firstWhere((c) => c.bookCode == 'ROM');
      expect(rom.textContent, startsWith('What then shall we say in response to these things?'));

      // Psalm 23
      final psa = kFeaturedChapters.firstWhere((c) => c.bookCode == 'PSA');
      expect(psa.textContent, startsWith('The LORD is my shepherd; I shall not want.'));

      // 1 Peter 5:7-9
      final pet = kFeaturedChapters.firstWhere((c) => c.bookCode == '1PE');
      expect(pet.textContent, startsWith('Casting all your anxieties on him'));
    });

    test('OfflineScriptureCache contains text for all 4 curated demo passages in BSB and WEB', () {
      final cache = OfflineScriptureCache(null);

      // 1 Corinthians 13
      expect(cache.getOfflineText('BSB', '1CO', 13), startsWith('Love is patient'));
      expect(cache.getOfflineText('WEB', '1CO', 13), startsWith('Love is patient'));

      // Matthew 11
      expect(cache.getOfflineText('BSB', 'MAT', 11), startsWith('Come to Me'));
      expect(cache.getOfflineText('WEB', 'MAT', 11), startsWith('Come to me'));

      // Romans 8
      expect(cache.getOfflineText('BSB', 'ROM', 8), startsWith('What then shall we say'));
      expect(cache.getOfflineText('WEB', 'ROM', 8), startsWith('What then shall we say'));

      // Psalm 23
      expect(cache.getOfflineText('BSB', 'PSA', 23), startsWith('The LORD is my shepherd'));
      expect(cache.getOfflineText('WEB', 'PSA', 23), startsWith('Yahweh is my shepherd'));
    });
  });
}
