import '../../../core/constants/bible_canon.dart';

/// Single source of truth for every Bible translation the app supports.
///
/// Each entry knows its API.Bible audio + text IDs and which testaments have
/// a human narrator, so routing is `translation.hasNarratorFor(book)` instead
/// of string comparisons scattered across the codebase.
enum BibleTranslation {
  bsb(
    code: 'BSB',
    shortLabel: 'BSB',
    fullName: 'Berean Standard Bible',
    audioBibleId: 'aadc8a2f4bdb467b-01',
    textBibleId: 'bba9f40183526463-01',
    hasOtNarrator: true,
    hasNtNarrator: true,
    isLicensed: false,
    copyright:
        'Berean Standard Bible (BSB) text and audio (narrated by Barry Hays) are dedicated to the public domain.',
  ),
  web(
    code: 'WEB',
    shortLabel: 'WEB',
    fullName: 'World English Bible',
    audioBibleId: '105a06b6146d11e7-01',
    textBibleId: '9879dbb7cfe39e4d-01',
    hasOtNarrator: false,
    hasNtNarrator: true,
    isLicensed: false,
    copyright: 'World English Bible (WEB) text is public domain. NT drama audio ℗ 2013 Hosanna.',
  ),
  niv(
    code: 'NIV',
    shortLabel: 'NIV',
    fullName: 'New International Version',
    audioBibleId: '5dd1a42b02d2dee6-01',
    textBibleId: '78a9f6124f344018-01',
    hasOtNarrator: true,
    hasNtNarrator: true,
    isLicensed: true,
    copyright:
        'The Holy Bible, New International Version® NIV® Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.® '
        'Used by Permission. All rights reserved worldwide. '
        'The Listener’s Bible®: NIV® Edition Audio ℗ 2011 by Max McLean. Used by permission.',
  );

  const BibleTranslation({
    required this.code,
    required this.shortLabel,
    required this.fullName,
    required this.audioBibleId,
    required this.textBibleId,
    required this.hasOtNarrator,
    required this.hasNtNarrator,
    required this.isLicensed,
    required this.copyright,
  });

  final String code;
  final String shortLabel;
  final String fullName;
  final String audioBibleId;
  final String textBibleId;
  final bool hasOtNarrator;
  final bool hasNtNarrator;

  /// True for copyrighted translations (e.g. NIV) that require copyright
  /// display and API.Bible FUMS reporting. See `niv_restrictions.md`.
  final bool isLicensed;
  final String copyright;

  static const BibleTranslation fallback = BibleTranslation.bsb;

  bool hasNarratorFor(String bookCode) =>
      BibleCanon.isOldTestament(bookCode) ? hasOtNarrator : hasNtNarrator;

  /// Human-readable coverage summary for settings UI.
  String get coverageLabel => switch ((hasOtNarrator, hasNtNarrator)) {
        (true, true) => 'OT + NT narrator',
        (false, true) => 'NT narrator · OT TTS',
        (true, false) => 'OT narrator · NT TTS',
        (false, false) => 'TTS only',
      };

  /// Short attribution line for player card and lockscreen displays.
  String get shortAttribution => switch (this) {
        BibleTranslation.bsb => 'Public Domain · Narrator: Barry Hays',
        BibleTranslation.web => 'Public Domain · Audio ℗ 2013 Hosanna',
        BibleTranslation.niv => 'NIV® © Biblica, Inc.® · Audio ℗ 2011 Max McLean',
      };

  /// Licensing badge label.
  String get badgeLabel => isLicensed ? 'Licensed Stream' : 'Public Domain';

  /// Human narrator credit string.
  String get narratorCredit => switch (this) {
        BibleTranslation.bsb => 'Barry Hays',
        BibleTranslation.web => 'Hosanna / Faith Comes By Hearing',
        BibleTranslation.niv => 'Max McLean (The Listener’s Bible®)',
      };

  /// Detailed audio streaming terms and offline caching boundary notice.
  String get audioLicensingTerms => switch (this) {
        BibleTranslation.bsb =>
          'Berean Standard Bible audio is dedicated to the public domain and may be cached offline freely.',
        BibleTranslation.web =>
          'World English Bible text is public domain. NT drama audio ℗ 2013 Hosanna is provided for streaming.',
        BibleTranslation.niv =>
          'Proprietary audio stream (Biblica / Zondervan / Fellowship for the Performing Arts). '
          'Streaming on-demand only under API.Bible terms. Permanent offline audio caching is prohibited. '
          'WhisperX timestamp alignment JSONs and text metadata are cached locally.',
      };

  /// Lenient lookup (case-insensitive); unknown/null codes fall back to BSB.
  static BibleTranslation fromCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    for (final t in values) {
      if (t.code == normalized) return t;
    }
    return fallback;
  }
}
