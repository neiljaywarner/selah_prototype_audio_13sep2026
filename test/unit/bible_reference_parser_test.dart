import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/picker/bible_reference_parser.dart';

void main() {
  group('BibleReferenceParser Tests', () {
    test('"Jn" matches John and Jonah', () {
      final suggestions = BibleReferenceParser.getSuggestions('Jn');
      final names = suggestions.map((s) => s.book.name).toList();

      expect(names, contains('John'));
      expect(names, contains('Jonah'));
    });

    test('"Col 3" parses Colossians chapter 3', () {
      final suggestions = BibleReferenceParser.getSuggestions('Col 3');
      expect(suggestions.isNotEmpty, isTrue);

      final first = suggestions.first;
      expect(first.book.code, 'COL');
      expect(first.chapter, 3);
      expect(first.displayName, 'Colossians 3');
    });

    test('"Colo" matches Colossians', () {
      final suggestions = BibleReferenceParser.getSuggestions('Colo');
      final names = suggestions.map((s) => s.book.name).toList();

      expect(names, contains('Colossians'));
    });

    test('"Ps 23" parses Psalms chapter 23', () {
      final suggestions = BibleReferenceParser.getSuggestions('Ps 23');
      expect(suggestions.isNotEmpty, isTrue);

      final first = suggestions.first;
      expect(first.book.code, 'PSA');
      expect(first.chapter, 23);
      expect(first.displayName, 'Psalms 23');
    });

    test('Clamps chapter to maximum chapters for book', () {
      // Obadiah has only 1 chapter
      final suggestions = BibleReferenceParser.getSuggestions('Obadiah 5');
      expect(suggestions.first.chapter, 1);
    });
  });
}
