import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/picker/bible_reference_parser.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';

import '../support/fixtures/passage_fixtures.dart';

void main() {
  group('Bible translation routing', () {
    test('unknown and blank codes fall back to BSB', () {
      expect(BibleTranslation.fromCode(null), BibleTranslation.bsb);
      expect(BibleTranslation.fromCode('  '), BibleTranslation.bsb);
      expect(BibleTranslation.fromCode('nope'), BibleTranslation.bsb);
      expect(BibleTranslation.fromCode('web'), BibleTranslation.web);
    });

    test('coverage labels tell the listener who can narrate', () {
      expect(BibleTranslation.bsb.coverageLabel, 'OT + NT narrator');
      expect(BibleTranslation.web.coverageLabel, 'NT narrator · OT TTS');
      expect(BibleTranslation.web.hasNarratorFor('GEN'), isFalse);
      expect(BibleTranslation.web.hasNarratorFor('JHN'), isTrue);
      expect(BibleTranslation.niv.badgeLabel, 'Licensed Stream');
      expect(BibleTranslation.bsb.badgeLabel, 'Public Domain');
      expect(BibleTranslation.esv.narratorCredit, contains('David Cochran Heath'));
      expect(BibleTranslation.niv.audioLicensingTerms, contains('offline'));
      expect(BibleTranslation.esv.shortAttribution, contains('Crossway'));
    });
  });

  group('Bible reference parser edge cases', () {
    test('blank input suggests nothing', () {
      expect(BibleReferenceParser.getSuggestions('   '), isEmpty);
      expect(BibleReferenceParser.findMatchingBooks(''), isEmpty);
    });

    test('a reference the canon does not know suggests nothing', () {
      expect(
        BibleReferenceParser.getSuggestions(PassageFixtures.unknownReference),
        isEmpty,
      );
    });

    test('1 John 3:16 keeps the verse, and chapter 9 clamps to 1 John', () {
      final parsed = BibleReferenceParser.getSuggestions('1 John 3:16');
      expect(parsed, isNotEmpty);
      expect(parsed.first.book.code, '1JN');
      expect(parsed.first.chapter, 3);
      expect(parsed.first.verse, 16);
      expect(parsed.first.displayName, '1 John 3:16');
      expect(parsed.first.codeReference, '1JN.3.16');

      final clamped = BibleReferenceParser.getSuggestions('1 John 9');
      expect(clamped.first.chapter, 5);
      expect(clamped.first.displayName, '1 John 5');
    });

    test('Jn still offers John before Jonah', () {
      final names = BibleReferenceParser.getSuggestions('Jn').map((s) => s.book.name);
      expect(names, ['John', 'Jonah']);
    });
  });

  group('ESV policy when no key is compiled in', () {
    test('passages stay on API.Bible translations and queries keep a hyphen', () {
      const policy = EsvPassagePolicy(
        esvConfigured: false,
        experimentalApiBibleNarrator: false,
      );

      expect(policy.useEsvForPassages, isFalse);
      expect(policy.showApiBibleTranslations, isTrue);
      expect(policy.defaultTranslationCode, 'BSB');
      expect(policy.selectableTranslations, BibleTranslation.values);
      expect(
        EsvPassagePolicy.normalizePassageQuery(' 1 Cor 13:4–7 '),
        '1 Cor 13:4-7',
      );
    });

    test('a configured key without the experimental narrator locks the picker to ESV', () {
      const policy = EsvPassagePolicy(
        esvConfigured: true,
        experimentalApiBibleNarrator: false,
      );

      expect(policy.useEsvForPassages, isTrue);
      expect(policy.showApiBibleTranslations, isFalse);
      expect(policy.defaultTranslationCode, 'ESV');
      expect(policy.selectableTranslations, [BibleTranslation.esv]);
    });
  });
}
