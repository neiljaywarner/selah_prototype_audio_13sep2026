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

    test('parseQuery recognizes books followed by spaces and triggers numeric readiness', () {
      // "John " with trailing space -> ready for numbers!
      final qJohnSpace = BibleCanon.parseQuery('John ');
      expect(qJohnSpace, isNotNull);
      expect(qJohnSpace!.book.code, 'JHN');
      expect(qJohnSpace.chapter, isNull);
      expect(qJohnSpace.hasTrailingSpace, isTrue);
      expect(qJohnSpace.isExactBook, isTrue);

      // "John 3" -> parsed chapter 3
      final qJohn3 = BibleCanon.parseQuery('John 3');
      expect(qJohn3, isNotNull);
      expect(qJohn3!.book.code, 'JHN');
      expect(qJohn3.chapter, 3);
      expect(qJohn3.hasTrailingSpace, isTrue);

      // "1 Cor 13" -> 1 Corinthians chapter 13
      final q1Cor13 = BibleCanon.parseQuery('1 Cor 13');
      expect(q1Cor13, isNotNull);
      expect(q1Cor13!.book.code, '1CO');
      expect(q1Cor13.chapter, 13);

      // "Rom 8" -> Romans chapter 8
      final qRom8 = BibleCanon.parseQuery('Rom 8');
      expect(qRom8, isNotNull);
      expect(qRom8!.book.code, 'ROM');
      expect(qRom8.chapter, 8);

      // "Psalms 23" -> Psalms chapter 23
      final qPsa23 = BibleCanon.parseQuery('Psalms 23');
      expect(qPsa23, isNotNull);
      expect(qPsa23!.book.code, 'PSA');
      expect(qPsa23.chapter, 23);

      // Incomplete prefix without space "Joh" -> not exact, no trailing space
      final qIncomplete = BibleCanon.parseQuery('Joh');
      expect(qIncomplete, isNotNull);
      expect(qIncomplete!.book.code, 'JHN');
      expect(qIncomplete.hasTrailingSpace, isFalse);
      expect(qIncomplete.isExactBook, isFalse);
    });
  });
}
