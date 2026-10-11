class BibleBook {
  final String code;
  final String name;
  final bool isOldTestament;
  final int totalChapters;

  const BibleBook({
    required this.code,
    required this.name,
    required this.isOldTestament,
    required this.totalChapters,
  });
}

class BibleCanon {
  static const List<BibleBook> books = [
    // Old Testament (39 books)
    BibleBook(code: 'GEN', name: 'Genesis', isOldTestament: true, totalChapters: 50),
    BibleBook(code: 'EXO', name: 'Exodus', isOldTestament: true, totalChapters: 40),
    BibleBook(code: 'LEV', name: 'Leviticus', isOldTestament: true, totalChapters: 27),
    BibleBook(code: 'NUM', name: 'Numbers', isOldTestament: true, totalChapters: 36),
    BibleBook(code: 'DEU', name: 'Deuteronomy', isOldTestament: true, totalChapters: 34),
    BibleBook(code: 'JOS', name: 'Joshua', isOldTestament: true, totalChapters: 24),
    BibleBook(code: 'JDG', name: 'Judges', isOldTestament: true, totalChapters: 21),
    BibleBook(code: 'RUT', name: 'Ruth', isOldTestament: true, totalChapters: 4),
    BibleBook(code: '1SA', name: '1 Samuel', isOldTestament: true, totalChapters: 31),
    BibleBook(code: '2SA', name: '2 Samuel', isOldTestament: true, totalChapters: 24),
    BibleBook(code: '1KI', name: '1 Kings', isOldTestament: true, totalChapters: 22),
    BibleBook(code: '2KI', name: '2 Kings', isOldTestament: true, totalChapters: 25),
    BibleBook(code: '1CH', name: '1 Chronicles', isOldTestament: true, totalChapters: 29),
    BibleBook(code: '2CH', name: '2 Chronicles', isOldTestament: true, totalChapters: 36),
    BibleBook(code: 'EZR', name: 'Ezra', isOldTestament: true, totalChapters: 10),
    BibleBook(code: 'NEH', name: 'Nehemiah', isOldTestament: true, totalChapters: 13),
    BibleBook(code: 'EST', name: 'Esther', isOldTestament: true, totalChapters: 10),
    BibleBook(code: 'JOB', name: 'Job', isOldTestament: true, totalChapters: 42),
    BibleBook(code: 'PSA', name: 'Psalms', isOldTestament: true, totalChapters: 150),
    BibleBook(code: 'PRO', name: 'Proverbs', isOldTestament: true, totalChapters: 31),
    BibleBook(code: 'ECC', name: 'Ecclesiastes', isOldTestament: true, totalChapters: 12),
    BibleBook(code: 'SNG', name: 'Song of Solomon', isOldTestament: true, totalChapters: 8),
    BibleBook(code: 'ISA', name: 'Isaiah', isOldTestament: true, totalChapters: 66),
    BibleBook(code: 'JER', name: 'Jeremiah', isOldTestament: true, totalChapters: 52),
    BibleBook(code: 'LAM', name: 'Lamentations', isOldTestament: true, totalChapters: 5),
    BibleBook(code: 'EZK', name: 'Ezekiel', isOldTestament: true, totalChapters: 48),
    BibleBook(code: 'DAN', name: 'Daniel', isOldTestament: true, totalChapters: 12),
    BibleBook(code: 'HOS', name: 'Hosea', isOldTestament: true, totalChapters: 14),
    BibleBook(code: 'JOL', name: 'Joel', isOldTestament: true, totalChapters: 3),
    BibleBook(code: 'AMO', name: 'Amos', isOldTestament: true, totalChapters: 9),
    BibleBook(code: 'OBA', name: 'Obadiah', isOldTestament: true, totalChapters: 1),
    BibleBook(code: 'JON', name: 'Jonah', isOldTestament: true, totalChapters: 4),
    BibleBook(code: 'MIC', name: 'Micah', isOldTestament: true, totalChapters: 7),
    BibleBook(code: 'NAM', name: 'Nahum', isOldTestament: true, totalChapters: 3),
    BibleBook(code: 'HAB', name: 'Habakkuk', isOldTestament: true, totalChapters: 3),
    BibleBook(code: 'ZEP', name: 'Zephaniah', isOldTestament: true, totalChapters: 3),
    BibleBook(code: 'HAG', name: 'Haggai', isOldTestament: true, totalChapters: 2),
    BibleBook(code: 'ZEC', name: 'Zechariah', isOldTestament: true, totalChapters: 14),
    BibleBook(code: 'MAL', name: 'Malachi', isOldTestament: true, totalChapters: 4),

    // New Testament (27 books)
    BibleBook(code: 'MAT', name: 'Matthew', isOldTestament: false, totalChapters: 28),
    BibleBook(code: 'MRK', name: 'Mark', isOldTestament: false, totalChapters: 16),
    BibleBook(code: 'LUK', name: 'Luke', isOldTestament: false, totalChapters: 24),
    BibleBook(code: 'JHN', name: 'John', isOldTestament: false, totalChapters: 21),
    BibleBook(code: 'ACT', name: 'Acts', isOldTestament: false, totalChapters: 28),
    BibleBook(code: 'ROM', name: 'Romans', isOldTestament: false, totalChapters: 16),
    BibleBook(code: '1CO', name: '1 Corinthians', isOldTestament: false, totalChapters: 16),
    BibleBook(code: '2CO', name: '2 Corinthians', isOldTestament: false, totalChapters: 13),
    BibleBook(code: 'GAL', name: 'Galatians', isOldTestament: false, totalChapters: 6),
    BibleBook(code: 'EPH', name: 'Ephesians', isOldTestament: false, totalChapters: 6),
    BibleBook(code: 'PHP', name: 'Philippians', isOldTestament: false, totalChapters: 4),
    BibleBook(code: 'COL', name: 'Colossians', isOldTestament: false, totalChapters: 4),
    BibleBook(code: '1TH', name: '1 Thessalonians', isOldTestament: false, totalChapters: 5),
    BibleBook(code: '2TH', name: '2 Thessalonians', isOldTestament: false, totalChapters: 3),
    BibleBook(code: '1TI', name: '1 Timothy', isOldTestament: false, totalChapters: 6),
    BibleBook(code: '2TI', name: '2 Timothy', isOldTestament: false, totalChapters: 4),
    BibleBook(code: 'TIT', name: 'Titus', isOldTestament: false, totalChapters: 3),
    BibleBook(code: 'PHM', name: 'Philemon', isOldTestament: false, totalChapters: 1),
    BibleBook(code: 'HEB', name: 'Hebrews', isOldTestament: false, totalChapters: 13),
    BibleBook(code: 'JAS', name: 'James', isOldTestament: false, totalChapters: 5),
    BibleBook(code: '1PE', name: '1 Peter', isOldTestament: false, totalChapters: 5),
    BibleBook(code: '2PE', name: '2 Peter', isOldTestament: false, totalChapters: 3),
    BibleBook(code: '1JN', name: '1 John', isOldTestament: false, totalChapters: 5),
    BibleBook(code: '2JN', name: '2 John', isOldTestament: false, totalChapters: 1),
    BibleBook(code: '3JN', name: '3 John', isOldTestament: false, totalChapters: 1),
    BibleBook(code: 'JUD', name: 'Jude', isOldTestament: false, totalChapters: 1),
    BibleBook(code: 'REV', name: 'Revelation', isOldTestament: false, totalChapters: 22),
  ];

  static final Map<String, BibleBook> _bookByCode = {
    for (final b in books) b.code: b,
  };

  static final Map<String, String> _aliases = {
    'GENESIS': 'GEN', 'GEN': 'GEN',
    'EXODUS': 'EXO', 'EXO': 'EXO', 'EX': 'EXO',
    'LEVITICUS': 'LEV', 'LEV': 'LEV',
    'NUMBERS': 'NUM', 'NUM': 'NUM',
    'DEUTERONOMY': 'DEU', 'DEU': 'DEU', 'DEUT': 'DEU',
    'JOSHUA': 'JOS', 'JOS': 'JOS', 'JOSH': 'JOS',
    'JUDGES': 'JDG', 'JDG': 'JDG', 'JUDG': 'JDG',
    'RUTH': 'RUT', 'RUT': 'RUT',
    'SAMUEL': '1SA', '1SAMUEL': '1SA', '1 SAMUEL': '1SA', '1SA': '1SA', '1SAM': '1SA', '1 SAM': '1SA',
    '2SAMUEL': '2SA', '2 SAMUEL': '2SA', '2SA': '2SA', '2SAM': '2SA', '2 SAM': '2SA',
    'KINGS': '1KI', '1KINGS': '1KI', '1 KINGS': '1KI', '1KI': '1KI', '1KGS': '1KI', '1 KGS': '1KI',
    '2KINGS': '2KI', '2 KINGS': '2KI', '2KI': '2KI', '2KGS': '2KI', '2 KGS': '2KI',
    'CHRONICLES': '1CH', '1CHRONICLES': '1CH', '1 CHRONICLES': '1CH', '1CH': '1CH', '1CHRON': '1CH', '1 CHRON': '1CH',
    '2CHRONICLES': '2CH', '2 CHRONICLES': '2CH', '2CH': '2CH', '2CHRON': '2CH', '2 CHRON': '2CH',
    'EZRA': 'EZR', 'EZR': 'EZR',
    'NEHEMIAH': 'NEH', 'NEH': 'NEH',
    'ESTHER': 'EST', 'EST': 'EST',
    'JOB': 'JOB',
    'PSALM': 'PSA', 'PSALMS': 'PSA', 'PSL': 'PSA', 'PSA': 'PSA', 'PS': 'PSA',
    'PROVERBS': 'PRO', 'PRO': 'PRO', 'PROV': 'PRO',
    'ECCLESIASTES': 'ECC', 'ECC': 'ECC', 'ECCL': 'ECC',
    'SONG': 'SNG', 'SONGS': 'SNG', 'SONG OF SOLOMON': 'SNG', 'SNG': 'SNG', 'SOS': 'SNG',
    'ISAIAH': 'ISA', 'ISA': 'ISA',
    'JEREMIAH': 'JER', 'JER': 'JER',
    'LAMENTATIONS': 'LAM', 'LAM': 'LAM',
    'EZEKIEL': 'EZK', 'EZK': 'EZK', 'EZEK': 'EZK',
    'DANIEL': 'DAN', 'DAN': 'DAN',
    'HOSEA': 'HOS', 'HOS': 'HOS',
    'JOEL': 'JOL', 'JOL': 'JOL',
    'AMOS': 'AMO', 'AMO': 'AMO',
    'OBADIAH': 'OBA', 'OBA': 'OBA',
    'JONAH': 'JON', 'JON': 'JON',
    'MICAH': 'MIC', 'MIC': 'MIC',
    'NAHUM': 'NAM', 'NAM': 'NAM',
    'HABAKKUK': 'HAB', 'HAB': 'HAB',
    'ZEPHANIAH': 'ZEP', 'ZEP': 'ZEP',
    'HAGGAI': 'HAG', 'HAG': 'HAG',
    'ZECHARIAH': 'ZEC', 'ZEC': 'ZEC',
    'MALACHI': 'MAL', 'MAL': 'MAL',
    'MATTHEW': 'MAT', 'MAT': 'MAT', 'MATT': 'MAT', 'MT': 'MAT',
    'MARK': 'MRK', 'MRK': 'MRK', 'MK': 'MRK',
    'LUKE': 'LUK', 'LUK': 'LUK', 'LK': 'LUK',
    'JOHN': 'JHN', 'JHN': 'JHN', 'JN': 'JHN',
    'ACTS': 'ACT', 'ACT': 'ACT',
    'ROMANS': 'ROM', 'ROM': 'ROM',
    'CORINTHIANS': '1CO', '1CORINTHIANS': '1CO', '1 CORINTHIANS': '1CO', '1CO': '1CO', '1COR': '1CO', '1 COR': '1CO',
    '2CORINTHIANS': '2CO', '2 CORINTHIANS': '2CO', '2CO': '2CO', '2COR': '2CO', '2 COR': '2CO',
    'GALATIANS': 'GAL', 'GAL': 'GAL',
    'EPHESIANS': 'EPH', 'EPH': 'EPH',
    'PHILIPPIANS': 'PHP', 'PHIL': 'PHP', 'PHP': 'PHP',
    'COLOSSIANS': 'COL', 'COL': 'COL',
    '1THESSALONIANS': '1TH', '1 THESSALONIANS': '1TH', '1TH': '1TH', '1THESS': '1TH', '1 THESS': '1TH',
    '2THESSALONIANS': '2TH', '2 THESSALONIANS': '2TH', '2TH': '2TH', '2THESS': '2TH', '2 THESS': '2TH',
    '1TIMOTHY': '1TI', '1 TIMOTHY': '1TI', '1TI': '1TI', '1TIM': '1TI', '1 TIM': '1TI',
    '2TIMOTHY': '2TI', '2 TIMOTHY': '2TI', '2TI': '2TI', '2TIM': '2TI', '2 TIM': '2TI',
    'TITUS': 'TIT', 'TIT': 'TIT',
    'PHILEMON': 'PHM', 'PHM': 'PHM',
    'HEBREWS': 'HEB', 'HEB': 'HEB',
    'JAMES': 'JAS', 'JAS': 'JAS',
    'PETER': '1PE', '1PETER': '1PE', '1 PETER': '1PE', '1PE': '1PE', '1PET': '1PE', '1 PET': '1PE',
    '2PETER': '2PE', '2 PETER': '2PE', '2PE': '2PE', '2PET': '2PE', '2 PET': '2PE',
    '1JOHN': '1JN', '1 JOHN': '1JN', '1JN': '1JN',
    '2JOHN': '2JN', '2 JOHN': '2JN', '2JN': '2JN',
    '3JOHN': '3JN', '3 JOHN': '3JN', '3JN': '3JN',
    'JUDE': 'JUD', 'JUD': 'JUD',
    'REVELATION': 'REV', 'REV': 'REV',
  };

  static BibleBook? findBook(String query) {
    final upper = query.trim().toUpperCase();
    if (_bookByCode.containsKey(upper)) return _bookByCode[upper];
    if (_aliases.containsKey(upper)) return _bookByCode[_aliases[upper]];
    for (final b in books) {
      if (b.name.toUpperCase().startsWith(upper) || b.code == upper) {
        return b;
      }
    }
    return null;
  }

  static BibleBook? findExactBook(String query) {
    final upper = query.trim().toUpperCase();
    if (_bookByCode.containsKey(upper)) return _bookByCode[upper];
    if (_aliases.containsKey(upper)) return _bookByCode[_aliases[upper]];
    for (final b in books) {
      if (b.name.toUpperCase() == upper || b.code == upper) {
        return b;
      }
    }
    return null;
  }

  /// Parses inputs such as "John ", "John 3", "1 Cor 13", "Rom 8", or "Psalms 23".
  /// Returns a [BookChapterQuery] containing the matched book, parsed chapter,
  /// whether the book name was explicitly followed by a space, and whether it's an exact match.
  static BookChapterQuery? parseQuery(String input) {
    if (input.trim().isEmpty) return null;

    final regex = RegExp(r'^([1-3]?\s*[a-zA-Z\s]+?)(?:\s+(\d+))?\s*$');
    final match = regex.firstMatch(input);
    if (match == null) return null;

    final bookPart = match.group(1)?.trim() ?? '';
    final chapterStr = match.group(2);
    final int? chapter = chapterStr != null ? int.tryParse(chapterStr) : null;

    final exactBook = findExactBook(bookPart);
    final book = exactBook ?? findBook(bookPart);
    if (book == null) return null;

    final isExact = exactBook != null;
    final hasTrailingSpace = input.endsWith(' ') || chapterStr != null;

    return BookChapterQuery(
      book: book,
      chapter: chapter,
      hasTrailingSpace: hasTrailingSpace,
      isExactBook: isExact,
    );
  }

  static bool isOldTestament(String bookCode) {
    final b = _bookByCode[bookCode.toUpperCase()];
    return b?.isOldTestament ?? false;
  }

  static int maxChapterFor(String bookCode) {
    final b = _bookByCode[bookCode.toUpperCase()];
    return b?.totalChapters ?? 1;
  }

  static bool isValidChapter(String bookCode, int chapter) {
    final maxCh = maxChapterFor(bookCode);
    return chapter >= 1 && chapter <= maxCh;
  }
}

class BookChapterQuery {
  final BibleBook book;
  final int? chapter;
  final bool hasTrailingSpace;
  final bool isExactBook;

  const BookChapterQuery({
    required this.book,
    this.chapter,
    required this.hasTrailingSpace,
    required this.isExactBook,
  });
}
