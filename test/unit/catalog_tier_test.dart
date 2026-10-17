import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  group('Catalog Tier & Biblical 40 Tests (v0.3.6)', () {
    test('CatalogTier has curated12, biblical40, and allPassages with valid metadata', () {
      expect(CatalogTier.values.length, 3);
      expect(CatalogTier.curated12.label, 'Curated 12');
      expect(CatalogTier.curated12.emoji, '🌿');
      expect(CatalogTier.biblical40.label, 'Biblical 40');
      expect(CatalogTier.biblical40.emoji, '📜');
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

    test('PassageExcerpt.forChapter resolves unique chapters across Biblical 40', () {
      final psalm46 = PassageExcerpt.forChapter('PSA', 46);
      expect(psalm46, isNotNull);
      expect(psalm46!.displayTitle, 'Psalm 46:1–10');
      expect(psalm46.theme, 'Be Still and Know');

      final isaiah43 = PassageExcerpt.forChapter('ISA', 43);
      expect(isaiah43, isNotNull);
      expect(isaiah43!.displayTitle, 'Isaiah 43:1–3');

      final matthew6 = PassageExcerpt.forChapter('MAT', 6);
      expect(matthew6, isNotNull);
      expect(matthew6!.displayTitle, 'Matt 6:25–34');
    });
  });
}
