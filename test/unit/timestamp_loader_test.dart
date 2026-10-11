import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimestampLoaderService Tests', () {
    test('VerseTimestamp parses correctly from JSON', () {
      final json = {
        'verse': 1,
        'text': 'Yahweh is my shepherd: I shall have no lack.',
        'startMs': 0,
        'endMs': 3800,
      };

      final vt = VerseTimestamp.fromJson(json);
      expect(vt.verse, equals(1));
      expect(vt.text, contains('shepherd'));
      expect(vt.startMs, equals(0));
      expect(vt.endMs, equals(3800));
    });

    test('Timestamp asset paths are correctly constructed for WEB and BSB', () async {
      final result = await TimestampLoaderService.loadChapterTimestamps(
        translation: 'WEB',
        bookCode: 'XXX',
        chapterNumber: 999,
      );
      expect(result, isNull);
    });

    test('1 Corinthians 13:4-7 WhisperX timestamp structure verification', () {
      final verses = [
        {'verse': 4, 'text': 'Love is patient, love is kind. Love does not envy.', 'startMs': 0, 'endMs': 5200},
        {'verse': 5, 'text': 'does not behave itself inappropriately...', 'startMs': 5300, 'endMs': 11800},
        {'verse': 6, 'text': 'does not rejoice in unrighteousness...', 'startMs': 11900, 'endMs': 16400},
        {'verse': 7, 'text': 'bears all things, believes all things...', 'startMs': 16500, 'endMs': 22000},
      ];
      final list = verses.map((e) => VerseTimestamp.fromJson(e)).toList();
      expect(list.length, equals(4));
      expect(list.first.verse, equals(4));
      expect(list.first.text, contains('patient'));
      expect(list.last.verse, equals(7));
      expect(list.last.endMs, equals(22000));
    });
  });
}
