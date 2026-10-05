import '../constants/bible_canon.dart';

class ParsedBibleReference {
  final BibleBook book;
  final int chapter;
  final int? verse;

  const ParsedBibleReference({
    required this.book,
    required this.chapter,
    this.verse,
  });

  String get displayName => verse != null ? '${book.name} $chapter:$verse' : '${book.name} $chapter';
  String get codeReference => verse != null ? '${book.code}.$chapter.$verse' : '${book.code}.$chapter';
}

class BibleReferenceParser {
  /// Matches a search string like "Jn", "Colo", "Col 3", "Psalm 23"
  /// Returns a list of candidate suggestions for autocomplete.
  static List<ParsedBibleReference> getSuggestions(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return const [];

    final normalized = raw.replaceAll(':', ' ').replaceAll('.', ' ');
    final parts = normalized.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return const [];

    String bookPart = parts[0];
    int chapterPart = 1;
    int? versePart;

    // Handle numbered books like "1 John" or "2 Kings"
    if ((parts[0] == '1' || parts[0] == '2' || parts[0] == '3') && parts.length >= 2) {
      bookPart = '${parts[0]} ${parts[1]}';
      if (parts.length >= 3) {
        chapterPart = int.tryParse(parts[2]) ?? 1;
      }
      if (parts.length >= 4) {
        versePart = int.tryParse(parts[3]);
      }
    } else {
      if (parts.length >= 2) {
        chapterPart = int.tryParse(parts[1]) ?? 1;
      }
      if (parts.length >= 3) {
        versePart = int.tryParse(parts[2]);
      }
    }

    final matchedBooks = findMatchingBooks(bookPart);
    final results = <ParsedBibleReference>[];

    for (final book in matchedBooks) {
      final safeChapter = chapterPart.clamp(1, book.totalChapters);
      results.add(
        ParsedBibleReference(
          book: book,
          chapter: safeChapter,
          verse: versePart,
        ),
      );
    }

    return results;
  }

  /// Finds all books matching a query (e.g. "Jn" -> [John, Jonah], "Col" -> [Colossians])
  static List<BibleBook> findMatchingBooks(String query) {
    final clean = query.trim().toUpperCase();
    if (clean.isEmpty) return const [];

    // Exact matches first
    final exact = BibleCanon.books.where((b) => b.code == clean || b.name.toUpperCase() == clean).toList();
    if (exact.isNotEmpty) return exact;

    final startsWith = <BibleBook>[];
    final contains = <BibleBook>[];

    for (final book in BibleCanon.books) {
      final nameUpper = book.name.toUpperCase();
      final codeUpper = book.code.toUpperCase();

      // Special abbreviation shortcuts
      if (clean == 'JN' && (book.code == 'JHN' || book.code == 'JON')) {
        startsWith.add(book);
        continue;
      }

      if (nameUpper.startsWith(clean) || codeUpper.startsWith(clean)) {
        startsWith.add(book);
      } else if (nameUpper.contains(clean)) {
        contains.add(book);
      }
    }

    return [...startsWith, ...contains];
  }
}
