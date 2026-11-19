import '../../../core/constants/api_constants.dart';
import '../../../core/constants/protestant_verse_counts.dart';
import 'bible_translation.dart';

/// Crossway allows at most 500 verses in one quotation.
const int kCrosswayMaxQuotedVerses = 500;

/// Share sheets stay readable past this many characters of scripture.
///
/// Public-domain quotes are cut on a word boundary. ESV quotes over the
/// budget are left out entirely: Crossway's terms say not to change the words.
const int kShareScriptureCharacterBudget = 1500;

/// Builds the text the share sheet shows.
///
/// A normal range includes the words already loaded for that translation,
/// the reference, a translation mark, and the play link. ESV also gets the
/// Crossway notice. The message is never scripture alone: the invitation,
/// the link, and the notice sit around the quote.
///
/// Oversized ESV ranges (500 verses, half a book, or the character budget)
/// and any passage whose words are not loaded fall back to the reference
/// and the link. NIV text is not pasted. BSB and WEB are not held to
/// Crossway's verse caps; only the character budget shortens them.
class PassageShareMessage {
  PassageShareMessage._();

  /// True when [verseSpan] can be quoted as ESV.
  ///
  /// A null span is a whole chapter. One- and two-chapter books are refused
  /// because that chapter can be half the book or the entire book.
  static bool esvRangeMayBeQuoted({
    required int? verseSpan,
    required int bookVerses,
    required int bookChapters,
  }) {
    if (verseSpan != null &&
        (verseSpan < 1 || verseSpan > kCrosswayMaxQuotedVerses)) {
      return false;
    }
    if (verseSpan == null) return bookChapters >= 3;
    if (bookVerses <= 0) return verseSpan <= 6;
    return verseSpan * 2 < bookVerses;
  }

  /// Words from the player that belong to [translation], or null.
  ///
  /// Does not fetch and does not speak. A different passage, a placeholder,
  /// NIV, ESV text that was not marked by the Crossway client, or another
  /// translation's bundled wording stays out. Audio may still be buffering;
  /// words already on screen are not held back for that.
  static String? textReadyToShare({
    required BibleTranslation translation,
    required String? onScreenText,
    required bool samePassage,
    String? bsbText,
    String? webText,
  }) {
    if (!samePassage) return null;
    final cleaned = _normalize(onScreenText);
    if (cleaned == null || _isPlaceholder(cleaned)) return null;
    if (translation == BibleTranslation.niv) return null;
    if (translation == BibleTranslation.esv) {
      if (!cleaned.endsWith(kEsvShortCopyright)) return null;
      return cleaned;
    }
    if (translation == BibleTranslation.web &&
        bsbText != null &&
        _same(cleaned, bsbText) &&
        (webText == null || !_same(cleaned, webText))) {
      return null;
    }
    if (translation == BibleTranslation.bsb &&
        webText != null &&
        _same(cleaned, webText) &&
        (bsbText == null || !_same(cleaned, bsbText))) {
      return null;
    }
    return cleaned;
  }

  /// Scripture body to paste, or null when the share must stay reference-only.
  static String? quotation({
    required int? verseSpan,
    required String bookCode,
    required int bookChapters,
    required BibleTranslation translation,
    required String? verseText,
  }) {
    final cleaned = _normalize(verseText);
    if (cleaned == null || _isPlaceholder(cleaned)) return null;
    if (translation == BibleTranslation.niv) return null;

    if (translation == BibleTranslation.esv) {
      final words = _stripTrailingEsvMark(cleaned);
      if (words.isEmpty) return null;
      if (!esvRangeMayBeQuoted(
        verseSpan: verseSpan,
        bookVerses: kProtestantVerseCounts[bookCode] ?? 0,
        bookChapters: bookChapters,
      )) {
        return null;
      }
      if (words.length > kShareScriptureCharacterBudget) return null;
      return words;
    }

    if (cleaned.length <= kShareScriptureCharacterBudget) return cleaned;
    return _truncate(cleaned, kShareScriptureCharacterBudget);
  }

  /// The lines under the invitation. [includesVerseText] is false when [body] is null.
  static ({String message, String? attribution, bool includesVerseText}) lines({
    required String canonical,
    required String url,
    required String? body,
    required String markCode,
    required String quotedNotice,
    required String? fallbackAttribution,
  }) {
    if (body == null) {
      final attribution = _shortAttribution(fallbackAttribution);
      final parts = <String>[
        'Listen to $canonical in Selah',
        url,
        ?attribution,
      ];
      return (
        message: parts.join('\n'),
        attribution: attribution,
        includesVerseText: false,
      );
    }
    final message =
        'Listen to $canonical in Selah\n'
        '\n'
        '$body\n'
        '($markCode)\n'
        '\n'
        '$url\n'
        '\n'
        '$quotedNotice';
    return (
      message: message,
      attribution: quotedNotice,
      includesVerseText: true,
    );
  }

  static String? _normalize(String? raw) {
    final trimmed = raw?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static bool _same(String a, String b) => _normalize(a) == _normalize(b);

  static bool _isPlaceholder(String text) {
    final lower = text.toLowerCase();
    if (lower.startsWith('press play to listen')) return true;
    if (lower.startsWith('this link does not open')) return true;
    return RegExp(
      r'^.+ chapter \d+\. "in the beginning was the word, and the word was with god, and the word was god\."$',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static String _stripTrailingEsvMark(String text) {
    final suffix = ' $kEsvShortCopyright';
    if (text.endsWith(suffix)) {
      return text.substring(0, text.length - suffix.length).trimRight();
    }
    if (text.endsWith(kEsvShortCopyright)) {
      return text
          .substring(0, text.length - kEsvShortCopyright.length)
          .trimRight();
    }
    return text;
  }

  static String _truncate(String text, int budget) {
    var end = budget;
    final slice = text.substring(0, end);
    final space = slice.lastIndexOf(' ');
    if (space >= budget ~/ 2) {
      end = space;
    }
    final cut = text.substring(0, end).trimRight();
    return '$cut…';
  }

  static String? _shortAttribution(String? attribution) {
    final trimmed = attribution?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.length > 180) return null;
    return trimmed;
  }
}
