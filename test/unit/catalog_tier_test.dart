import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  group('Catalog Tier & Soft Launch 77 Tests (v0.3.7)', () {
    test('CatalogTier has curated12, biblical40, softLaunch77, and allPassages with valid metadata', () {
      expect(CatalogTier.values.length, 4);
      expect(CatalogTier.curated12.label, 'Curated 12');
      expect(CatalogTier.curated12.emoji, '🌿');
      expect(CatalogTier.biblical40.label, 'Biblical 40');
      expect(CatalogTier.biblical40.emoji, '📜');
      expect(CatalogTier.softLaunch77.label, 'The 77 Cohort');
      expect(CatalogTier.softLaunch77.emoji, '🕊️');
      expect(CatalogTier.allPassages.label, 'All 66 Books');
      expect(CatalogTier.allPassages.emoji, '📖');
    });

    test('kCurated12Excerpts contains exactly 12 passages', () {
      expect(kCurated12Excerpts.length, 12);
      expect(kCurated12Excerpts.first.bookCode, '1CO');
      expect(kCurated12Excerpts.first.chapterNumber, 13);
      expect(kCurated12Excerpts.last.bookCode, 'ROM');
      expect(kCurated12Excerpts.last.chapterNumber, 12);
    });

    test('kBiblical40Excerpts contains exactly 40 passages with non-null themes', () {
      expect(kBiblical40Excerpts.length, 40);
      for (final excerpt in kBiblical40Excerpts) {
        expect(excerpt.theme, isNotNull, reason: '${excerpt.displayTitle} theme must not be null');
        expect(excerpt.theme!.trim(), isNotEmpty);
      }
    });

    test('kSoftLaunch77Excerpts contains exactly 77 passages with unique chapters and non-null themes', () {
      expect(kSoftLaunch77Excerpts.length, 77);
      final seenKeys = <String>{};
      for (final excerpt in kSoftLaunch77Excerpts) {
        final key = '${excerpt.bookCode}_${excerpt.chapterNumber}';
        expect(
          seenKeys.contains(key),
          isFalse,
          reason: 'Duplicate chapter mapping found: $key for ${excerpt.displayTitle}',
        );
        seenKeys.add(key);
        expect(excerpt.theme, isNotNull, reason: '${excerpt.displayTitle} theme must not be null');
        expect(excerpt.theme!.trim(), isNotEmpty);
        expect(excerpt.displayTitle, isNotNull);
        expect(excerpt.endVerse, greaterThanOrEqualTo(excerpt.startVerse));
      }
    });

    test('PassageExcerpt.forChapter resolves unique chapters across The 77 Cohort', () {
      final psalm46 = PassageExcerpt.forChapter('PSA', 46);
      expect(psalm46, isNotNull);
      expect(psalm46!.displayTitle, 'Psalm 46:1–10');
      expect(psalm46.theme, 'Be Still and Know');

      final psalm1 = PassageExcerpt.forChapter('PSA', 1);
      expect(psalm1, isNotNull);
      expect(psalm1!.displayTitle, 'Psalm 1:1–3');

      final john15 = PassageExcerpt.forChapter('JHN', 15);
      expect(john15, isNotNull);
      expect(john15!.displayTitle, 'John 15:1–5');

      final habakkuk3 = PassageExcerpt.forChapter('HAB', 3);
      expect(habakkuk3, isNotNull);
      expect(habakkuk3!.displayTitle, 'Hab 3:17–19');
    });
  });
}
