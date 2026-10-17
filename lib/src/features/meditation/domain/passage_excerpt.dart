import '../../../core/karaoke/timestamp_loader.dart';

/// Audio window `[start, end)` within a full-chapter narrator stream.
typedef ClipWindow = ({Duration start, Duration end});

/// A curated verse range within a chapter (e.g. 1 Corinthians 13:4–7).
///
/// API.Bible streams whole chapters, so an excerpt is played by clipping the
/// stream to the window spanned by its verse timestamps.
class PassageExcerpt {
  const PassageExcerpt({
    required this.bookCode,
    required this.chapterNumber,
    required this.startVerse,
    required this.endVerse,
    this.displayTitle,
    this.theme,
  });

  final String bookCode;
  final int chapterNumber;
  final int startVerse;
  final int endVerse;
  final String? displayTitle;
  final String? theme;

  /// Returns the curated excerpt for a chapter, or `null` when the chapter
  /// should play in full.
  static PassageExcerpt? forChapter(String bookCode, int chapterNumber) {
    final code = bookCode.toUpperCase();
    for (final excerpt in kCuratedExcerpts) {
      if (excerpt.bookCode == code && excerpt.chapterNumber == chapterNumber) {
        return excerpt;
      }
    }
    return null;
  }

  /// Creates a custom or dynamic passage excerpt for any arbitrary verse range.
  static PassageExcerpt? customExcerpt({
    required String bookCode,
    required int chapterNumber,
    required int startVerse,
    required int endVerse,
    String? displayTitle,
    String? theme,
  }) {
    if (startVerse <= 0 || endVerse < startVerse) return null;
    return PassageExcerpt(
      bookCode: bookCode.toUpperCase(),
      chapterNumber: chapterNumber,
      startVerse: startVerse,
      endVerse: endVerse,
      displayTitle: displayTitle,
      theme: theme,
    );
  }

  /// Computes the audio window from the first verse's start to the last
  /// verse's end, or `null` if no timestamps fall inside this excerpt.
  ClipWindow? clipWindow(List<VerseTimestamp>? timestamps) {
    final inRange = (timestamps ?? const <VerseTimestamp>[])
        .where((t) => t.verse >= startVerse && t.verse <= endVerse)
        .toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));
    if (inRange.isEmpty) return null;

    // Reject incomplete ranges: both startVerse and endVerse must be present
    final hasStart = inRange.any((t) => t.verse == startVerse);
    final hasEnd = inRange.any((t) => t.verse == endVerse);
    if (!hasStart || !hasEnd) return null;

    final start = inRange.first.startMs;
    final end = inRange.map((t) => t.endMs).reduce((a, b) => a > b ? a : b);
    if (end <= start) return null;

    return (start: Duration(milliseconds: start), end: Duration(milliseconds: end));
  }
}

/// The Top 12 Foundation Curated Meditations
List<PassageExcerpt> get kCurated12Excerpts => kCuratedExcerpts.sublist(0, 12);

/// The Biblical 40 Meditations (Wilderness, Renewal, Healing, and Peace)
List<PassageExcerpt> get kBiblical40Excerpts => kCuratedExcerpts;

const kCuratedExcerpts = [
  // --- Tier 1: Curated 12 Foundation ---
  PassageExcerpt(
    bookCode: '1CO',
    chapterNumber: 13,
    startVerse: 4,
    endVerse: 7,
    displayTitle: '1 Cor 13:4–7',
    theme: 'Love Is Patient, Love Is Kind',
  ),
  PassageExcerpt(
    bookCode: 'MAT',
    chapterNumber: 11,
    startVerse: 28,
    endVerse: 30,
    displayTitle: 'Matt 11:28–30',
    theme: 'Rest for the Weary',
  ),
  PassageExcerpt(
    bookCode: 'ROM',
    chapterNumber: 8,
    startVerse: 31,
    endVerse: 39,
    displayTitle: 'Rom 8:31–39',
    theme: 'More Than Conquerors',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 23,
    startVerse: 1,
    endVerse: 6,
    displayTitle: 'Psalm 23',
    theme: 'The Lord Is My Shepherd',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 62,
    startVerse: 1,
    endVerse: 2,
    displayTitle: 'Psalm 62:1–2',
    theme: 'My Soul Finds Rest in God',
  ),
  PassageExcerpt(
    bookCode: 'COL',
    chapterNumber: 1,
    startVerse: 1,
    endVerse: 2,
    displayTitle: 'Col 1:1–2',
    theme: 'Grace and Peace from God',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 91,
    startVerse: 1,
    endVerse: 4,
    displayTitle: 'Psalm 91:1–4',
    theme: 'Shelter of the Most High',
  ),
  PassageExcerpt(
    bookCode: 'JHN',
    chapterNumber: 3,
    startVerse: 16,
    endVerse: 17,
    displayTitle: 'John 3:16–17',
    theme: 'For God So Loved the World',
  ),
  PassageExcerpt(
    bookCode: 'PHP',
    chapterNumber: 4,
    startVerse: 4,
    endVerse: 8,
    displayTitle: 'Phil 4:4–8',
    theme: 'The Peace of God',
  ),
  PassageExcerpt(
    bookCode: 'PRO',
    chapterNumber: 3,
    startVerse: 5,
    endVerse: 6,
    displayTitle: 'Prov 3:5–6',
    theme: 'Trust in the Lord with All Your Heart',
  ),
  PassageExcerpt(
    bookCode: 'ISA',
    chapterNumber: 40,
    startVerse: 28,
    endVerse: 31,
    displayTitle: 'Isaiah 40:28–31',
    theme: 'Those Who Wait on the Lord',
  ),
  PassageExcerpt(
    bookCode: 'ROM',
    chapterNumber: 12,
    startVerse: 1,
    endVerse: 2,
    displayTitle: 'Rom 12:1–2',
    theme: 'A Living Sacrifice',
  ),

  // --- Tier 2: Biblical 40 (Passages 13–40: Wilderness, Renewal & Peace) ---
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 46,
    startVerse: 1,
    endVerse: 10,
    displayTitle: 'Psalm 46:1–10',
    theme: 'Be Still and Know',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 139,
    startVerse: 1,
    endVerse: 10,
    displayTitle: 'Psalm 139:1–10',
    theme: 'Search Me and Know Me',
  ),
  PassageExcerpt(
    bookCode: 'ISA',
    chapterNumber: 43,
    startVerse: 1,
    endVerse: 3,
    displayTitle: 'Isaiah 43:1–3',
    theme: 'Fear Not, Called By Name',
  ),
  PassageExcerpt(
    bookCode: 'EXO',
    chapterNumber: 14,
    startVerse: 13,
    endVerse: 14,
    displayTitle: 'Exodus 14:13–14',
    theme: 'The Lord Will Fight For You',
  ),
  PassageExcerpt(
    bookCode: 'MAT',
    chapterNumber: 6,
    startVerse: 25,
    endVerse: 34,
    displayTitle: 'Matt 6:25–34',
    theme: 'Do Not Be Anxious',
  ),
  PassageExcerpt(
    bookCode: 'LAM',
    chapterNumber: 3,
    startVerse: 22,
    endVerse: 26,
    displayTitle: 'Lam 3:22–26',
    theme: 'Mercies New Every Morning',
  ),
  PassageExcerpt(
    bookCode: '2CO',
    chapterNumber: 12,
    startVerse: 9,
    endVerse: 10,
    displayTitle: '2 Cor 12:9–10',
    theme: 'My Grace Is Sufficient',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 27,
    startVerse: 1,
    endVerse: 4,
    displayTitle: 'Psalm 27:1–4',
    theme: 'The Lord Is My Light',
  ),
  PassageExcerpt(
    bookCode: 'ISA',
    chapterNumber: 26,
    startVerse: 3,
    endVerse: 4,
    displayTitle: 'Isaiah 26:3–4',
    theme: 'Perfect Peace',
  ),
  PassageExcerpt(
    bookCode: 'ZEP',
    chapterNumber: 3,
    startVerse: 17,
    endVerse: 17,
    displayTitle: 'Zephaniah 3:17',
    theme: 'Rejoicing Over You With Singing',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 121,
    startVerse: 1,
    endVerse: 8,
    displayTitle: 'Psalm 121:1–8',
    theme: 'My Help Comes From the Lord',
  ),
  PassageExcerpt(
    bookCode: 'JHN',
    chapterNumber: 14,
    startVerse: 1,
    endVerse: 3,
    displayTitle: 'John 14:1–3',
    theme: 'Peace I Leave With You',
  ),
  PassageExcerpt(
    bookCode: 'EPH',
    chapterNumber: 3,
    startVerse: 16,
    endVerse: 21,
    displayTitle: 'Eph 3:16–21',
    theme: 'Rooted and Grounded in Love',
  ),
  PassageExcerpt(
    bookCode: 'ROM',
    chapterNumber: 5,
    startVerse: 1,
    endVerse: 5,
    displayTitle: 'Rom 5:1–5',
    theme: 'Peace with God and Hope',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 84,
    startVerse: 1,
    endVerse: 4,
    displayTitle: 'Psalm 84:1–4',
    theme: 'How Lovely Is Your Dwelling Place',
  ),
  PassageExcerpt(
    bookCode: 'HEB',
    chapterNumber: 4,
    startVerse: 14,
    endVerse: 16,
    displayTitle: 'Heb 4:14–16',
    theme: 'The Throne of Grace',
  ),
  PassageExcerpt(
    bookCode: '1PE',
    chapterNumber: 5,
    startVerse: 6,
    endVerse: 7,
    displayTitle: '1 Peter 5:6–7',
    theme: 'Cast All Your Anxiety on Him',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 103,
    startVerse: 1,
    endVerse: 5,
    displayTitle: 'Psalm 103:1–5',
    theme: 'Bless the Lord, O My Soul',
  ),
  PassageExcerpt(
    bookCode: 'ISA',
    chapterNumber: 55,
    startVerse: 1,
    endVerse: 3,
    displayTitle: 'Isaiah 55:1–3',
    theme: 'Come to the Waters',
  ),
  PassageExcerpt(
    bookCode: 'MAT',
    chapterNumber: 5,
    startVerse: 3,
    endVerse: 10,
    displayTitle: 'Matt 5:3–10',
    theme: 'The Beatitudes',
  ),
  PassageExcerpt(
    bookCode: '1JN',
    chapterNumber: 4,
    startVerse: 16,
    endVerse: 19,
    displayTitle: '1 John 4:16–19',
    theme: 'Perfect Love Drives Out Fear',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 34,
    startVerse: 1,
    endVerse: 8,
    displayTitle: 'Psalm 34:1–8',
    theme: 'Taste and See That the Lord Is Good',
  ),
  PassageExcerpt(
    bookCode: 'JOS',
    chapterNumber: 1,
    startVerse: 8,
    endVerse: 9,
    displayTitle: 'Joshua 1:8–9',
    theme: 'Be Strong and Courageous',
  ),
  PassageExcerpt(
    bookCode: '2CO',
    chapterNumber: 4,
    startVerse: 16,
    endVerse: 18,
    displayTitle: '2 Cor 4:16–18',
    theme: 'Renewed Day by Day',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 42,
    startVerse: 1,
    endVerse: 2,
    displayTitle: 'Psalm 42:1–2',
    theme: 'As the Deer Pants for Streams',
  ),
  PassageExcerpt(
    bookCode: 'GAL',
    chapterNumber: 5,
    startVerse: 22,
    endVerse: 25,
    displayTitle: 'Gal 5:22–25',
    theme: 'The Fruit of the Spirit',
  ),
  PassageExcerpt(
    bookCode: 'REV',
    chapterNumber: 21,
    startVerse: 3,
    endVerse: 5,
    displayTitle: 'Rev 21:3–5',
    theme: 'Behold, I Make All Things New',
  ),
  PassageExcerpt(
    bookCode: 'DEU',
    chapterNumber: 6,
    startVerse: 4,
    endVerse: 9,
    displayTitle: 'Deut 6:4–9',
    theme: 'The Shema (Hear, O Israel)',
  ),
];
