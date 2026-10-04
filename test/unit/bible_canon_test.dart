import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/constants/bible_canon.dart';

void main() {
  group('BibleCanon Tests', () {
    test('Has exactly 66 canonical books', () {
      expect(BibleCanon.books.length, 66);
    });

    test('Has 39 Old Testament and 27 New Testament books', () {
      final ot = BibleCanon.books.where((b) => b.isOldTestament).toList();
      final nt = BibleCanon.books.where((b) => !b.isOldTestament).toList();

      expect(ot.length, 39);
      expect(nt.length, 27);
    });

    test('Correctly identifies Old Testament vs New Testament', () {
      expect(BibleCanon.isOldTestament('GEN'), isTrue);
      expect(BibleCanon.isOldTestament('PSA'), isTrue);
      expect(BibleCanon.isOldTestament('MAL'), isTrue);

      expect(BibleCanon.isOldTestament('MAT'), isFalse);
      expect(BibleCanon.isOldTestament('COL'), isFalse);
      expect(BibleCanon.isOldTestament('REV'), isFalse);
    });

    test('Validates canonical chapter counts accurately', () {
      // Genesis has 50 chapters
      expect(BibleCanon.maxChapterFor('GEN'), 50);
      expect(BibleCanon.isValidChapter('GEN', 1), isTrue);
      expect(BibleCanon.isValidChapter('GEN', 50), isTrue);
      expect(BibleCanon.isValidChapter('GEN', 51), isFalse);

      // Psalms has 150 chapters
      expect(BibleCanon.maxChapterFor('PSA'), 150);
      expect(BibleCanon.isValidChapter('PSA', 23), isTrue);
      expect(BibleCanon.isValidChapter('PSA', 151), isFalse);

      // Colossians has 4 chapters
      expect(BibleCanon.maxChapterFor('COL'), 4);
      expect(BibleCanon.isValidChapter('COL', 1), isTrue);
      expect(BibleCanon.isValidChapter('COL', 5), isFalse);

      // Obadiah and Jude have 1 chapter
      expect(BibleCanon.maxChapterFor('OBA'), 1);
      expect(BibleCanon.isValidChapter('OBA', 2), isFalse);

      expect(BibleCanon.maxChapterFor('JUD'), 1);
      expect(BibleCanon.isValidChapter('JUD', 1), isTrue);
      expect(BibleCanon.isValidChapter('JUD', 2), isFalse);
    });

    test('Finds books by code and common names/aliases', () {
      expect(BibleCanon.findBook('PSA')?.code, 'PSA');
      expect(BibleCanon.findBook('Psalm')?.code, 'PSA');
      expect(BibleCanon.findBook('Psalms')?.code, 'PSA');
      expect(BibleCanon.findBook('John')?.code, 'JHN');
      expect(BibleCanon.findBook('Colossians')?.code, 'COL');
      expect(BibleCanon.findBook('COL')?.code, 'COL');
    });
  });
}
