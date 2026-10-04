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
    'GENESIS': 'GEN',
    'EXODUS': 'EXO',
    'LEVITICUS': 'LEV',
    'NUMBERS': 'NUM',
    'DEUTERONOMY': 'DEU',
    'JOSHUA': 'JOS',
    'JUDGES': 'JDG',
    'RUTH': 'RUT',
    'SAMUEL': '1SA',
    'PSALM': 'PSA',
    'PSALMS': 'PSA',
    'PSL': 'PSA',
    'PROVERBS': 'PRO',
    'ECCLESIASTES': 'ECC',
    'SONG': 'SNG',
    'ISAIAH': 'ISA',
    'JEREMIAH': 'JER',
    'LAMENTATIONS': 'LAM',
    'EZEKIEL': 'EZK',
    'DANIEL': 'DAN',
    'MATTHEW': 'MAT',
    'MARK': 'MRK',
    'LUKE': 'LUK',
    'JOHN': 'JHN',
    'ACTS': 'ACT',
    'ROMANS': 'ROM',
    'CORINTHIANS': '1CO',
    'GALATIANS': 'GAL',
    'EPHESIANS': 'EPH',
    'PHILIPPIANS': 'PHP',
    'COLOSSIANS': 'COL',
    'HEBREWS': 'HEB',
    'JAMES': 'JAS',
    'PETER': '1PE',
    'JUDE': 'JUD',
    'REVELATION': 'REV',
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
