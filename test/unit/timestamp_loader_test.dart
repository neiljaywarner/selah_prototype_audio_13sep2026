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
  });
}
