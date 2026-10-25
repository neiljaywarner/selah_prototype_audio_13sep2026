import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';

void main() {
  group('EsvPassagePolicy', () {
    test('ESV configured + experimental off uses ESV only for passages', () {
      const policy = EsvPassagePolicy(esvConfigured: true, experimentalApiBibleNarrator: false);
      expect(policy.useEsvForPassages, isTrue);
      expect(policy.showApiBibleTranslations, isFalse);
      expect(policy.defaultTranslationCode, 'ESV');
      expect(policy.selectableTranslations, [BibleTranslation.esv]);
    });

    test('ESV configured + experimental on exposes API.Bible translations', () {
      const policy = EsvPassagePolicy(esvConfigured: true, experimentalApiBibleNarrator: true);
      expect(policy.useEsvForPassages, isFalse);
      expect(policy.showApiBibleTranslations, isTrue);
      expect(policy.selectableTranslations.length, BibleTranslation.values.length);
    });

    test('ESV not configured keeps legacy API.Bible default', () {
      const policy = EsvPassagePolicy(esvConfigured: false, experimentalApiBibleNarrator: false);
      expect(policy.useEsvForPassages, isFalse);
      expect(policy.showApiBibleTranslations, isTrue);
      expect(policy.defaultTranslationCode, BibleTranslation.fallback.code);
    });

    test('normalizePassageQuery converts en dash to hyphen', () {
      expect(
        EsvPassagePolicy.normalizePassageQuery('1 Cor 13:4–7'),
        '1 Cor 13:4-7',
      );
    });

    test('ChapterInfo with displayTitle formats reference cleanly without appending chapterNumber', () {
      final info = ChapterInfo(
        bookCode: 'VRS',
        bookName: '1 Corinthians 13:4–7',
        chapterNumber: 1,
        displayTitle: '1 Corinthians 13:4–7',
        audioStreamUrl: '',
        textContent: 'Love is patient...',
      );
      expect(info.reference, '1 Corinthians 13:4–7');
    });
  });
}
