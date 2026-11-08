import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/cache/offline_scripture_cache.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/cache/public_domain_passage_text.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const curatedOpening = 'My soul finds rest in God alone';
  const sharedOpening = 'Rest in God alone, O my soul';

  group('Offline scripture for a shared range', () {
    test('Psalm 62:5-7 is BSB 5-7 and not the curated 62:1-2 excerpt', () {
      final cache = OfflineScriptureCache(null);
      final shared = cache.getOfflineText('BSB', 'PSA', 62, startVerse: 5, endVerse: 7);
      final curated = cache.getOfflineText('BSB', 'PSA', 62, startVerse: 1, endVerse: 2);

      expect(shared, isNotNull);
      expect(shared, contains(sharedOpening));
      expect(shared, contains('my hope comes from Him'));
      expect(shared, contains('my refuge is in God'));
      expect(shared, isNot(contains(curatedOpening)));
      expect(shared, isNot(contains('I will never be shaken')));
      expect(curated, contains(curatedOpening));
      expect(curated, isNot(equals(shared)));
    });

    test('a range that is not the curated window does not borrow that window', () {
      final cache = OfflineScriptureCache(null);
      expect(
        cache.getOfflineText('BSB', '1CO', 13, startVerse: 8, endVerse: 13),
        isNull,
      );
      expect(
        cache.getOfflineText('BSB', '1CO', 13, startVerse: 4, endVerse: 7),
        contains('Love is patient'),
      );
    });
  });

  group('Helloao public-domain range', () {
    test('joins only the requested verses', () {
      final text = PublicDomainPassageText.textFromHelloAoBody(
        {
          'chapter': {
            'content': [
              {'type': 'heading', 'content': ['A psalm']},
              {
                'type': 'verse',
                'number': 5,
                'content': [
                  {'text': 'Rest in God alone, O my soul,'},
                  {'text': 'for my hope comes from Him.'},
                ],
              },
              {
                'type': 'verse',
                'number': 6,
                'content': ['He is my fortress; I will not be shaken.'],
              },
            ],
          },
        },
        startVerse: 5,
        endVerse: 6,
      );
      expect(text, contains('Rest in God alone, O my soul,'));
      expect(text, contains('for my hope comes from Him.'));
      expect(text, contains('I will not be shaken'));
      expect(text, isNot(contains(curatedOpening)));
    });

    test('returns null when the range is incomplete', () {
      expect(
        PublicDomainPassageText.textFromHelloAoBody(
          {
            'chapter': {
              'content': [
                {'type': 'verse', 'number': 5, 'content': ['Rest in God alone.']},
              ],
            },
          },
          startVerse: 5,
          endVerse: 7,
        ),
        isNull,
      );
    });
  });

  group('ESV still requests the shared range', () {
    test('a custom share excerpt is not the curated Psalm 62 query', () {
      final shared = PassageExcerpt.customExcerpt(
        bookCode: 'PSA',
        chapterNumber: 62,
        startVerse: 5,
        endVerse: 7,
        displayTitle: 'Psalm 62:5-7',
      );
      final curated = PassageExcerpt.forChapter('PSA', 62);

      expect(shared!.toEsvPassageQuery(), 'Psalm 62:5-7');
      expect(curated!.startVerse, 1);
      expect(curated.endVerse, 2);
      expect(curated.toEsvPassageQuery(), isNot('Psalm 62:5-7'));
      expect(
        EsvApiClient.expandToSingleVerses(shared.toEsvPassageQuery()),
        ['Psalm 62:5', 'Psalm 62:6', 'Psalm 62:7'],
      );
      expect(
        EsvApiClient.expandToSingleVerses(curated.toEsvPassageQuery()),
        isNot(contains('Psalm 62:5')),
      );
    });
  });
}
