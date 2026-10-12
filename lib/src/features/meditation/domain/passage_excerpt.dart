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
  });

  final String bookCode;
  final int chapterNumber;
  final int startVerse;
  final int endVerse;
  final String? displayTitle;

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
  }) {
    if (startVerse <= 0 || endVerse < startVerse) return null;
    return PassageExcerpt(
      bookCode: bookCode.toUpperCase(),
      chapterNumber: chapterNumber,
      startVerse: startVerse,
      endVerse: endVerse,
      displayTitle: displayTitle,
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

    final start = inRange.first.startMs;
    final end = inRange.map((t) => t.endMs).reduce((a, b) => a > b ? a : b);
    if (end <= start) return null;

    return (start: Duration(milliseconds: start), end: Duration(milliseconds: end));
  }
}

const kCuratedExcerpts = [
  PassageExcerpt(
    bookCode: '1CO',
    chapterNumber: 13,
    startVerse: 4,
    endVerse: 7,
    displayTitle: '1 Cor 13:4–7',
  ),
  PassageExcerpt(
    bookCode: 'MAT',
    chapterNumber: 11,
    startVerse: 28,
    endVerse: 30,
    displayTitle: 'Matt 11:28–30',
  ),
  PassageExcerpt(
    bookCode: 'ROM',
    chapterNumber: 8,
    startVerse: 31,
    endVerse: 39,
    displayTitle: 'Rom 8:31–39',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 23,
    startVerse: 1,
    endVerse: 6,
    displayTitle: 'Psalm 23',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 62,
    startVerse: 1,
    endVerse: 2,
    displayTitle: 'Psalm 62:1–2',
  ),
  PassageExcerpt(
    bookCode: 'COL',
    chapterNumber: 1,
    startVerse: 1,
    endVerse: 2,
    displayTitle: 'Col 1:1–2',
  ),
  PassageExcerpt(
    bookCode: 'PSA',
    chapterNumber: 91,
    startVerse: 1,
    endVerse: 4,
    displayTitle: 'Psalm 91:1–4',
  ),
  PassageExcerpt(
    bookCode: 'JHN',
    chapterNumber: 3,
    startVerse: 16,
    endVerse: 17,
    displayTitle: 'John 3:16–17',
  ),
  PassageExcerpt(
    bookCode: 'PHP',
    chapterNumber: 4,
    startVerse: 4,
    endVerse: 8,
    displayTitle: 'Phil 4:4–8',
  ),
  PassageExcerpt(
    bookCode: 'PRO',
    chapterNumber: 3,
    startVerse: 5,
    endVerse: 6,
    displayTitle: 'Prov 3:5–6',
  ),
  PassageExcerpt(
    bookCode: 'ISA',
    chapterNumber: 40,
    startVerse: 28,
    endVerse: 31,
    displayTitle: 'Isaiah 40:28–31',
  ),
  PassageExcerpt(
    bookCode: 'ROM',
    chapterNumber: 12,
    startVerse: 1,
    endVerse: 2,
    displayTitle: 'Rom 12:1–2',
  ),
];
