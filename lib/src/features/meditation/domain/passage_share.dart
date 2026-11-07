import 'dart:convert';

import '../../../core/constants/bible_canon.dart';

/// A Bible reference a listener can send to someone else.
///
/// The share URL and the share-sheet text carry this reference only.
/// Copyrighted verse text stays in the player, where the app loads it the
/// normal way.
class SharedPassage {
  const SharedPassage({
    required this.book,
    required this.chapter,
    required this.canonical,
    this.startVerse,
    this.endVerse,
  });

  final BibleBook book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  /// Stable reading form, for example `1 Cor 13:4-7`.
  final String canonical;

  bool get hasVerseRange => startVerse != null;
}

/// What the platform share sheet and the copied link receive.
class PassageSharePayload {
  const PassageSharePayload({
    required this.reference,
    required this.url,
    required this.message,
    this.attribution,
  });

  final String reference;
  final String url;
  final String message;
  final String? attribution;

  /// Reference, link, and optional short attribution. Never the verse body.
  String get sharedText => message;
}

/// A saved My Passages row that is safe to share.
class SavedShareItem {
  const SavedShareItem({required this.stored, required this.passage});

  /// Original preference value (plain reference, or the JSON form from
  /// exact-ref persistence).
  final String stored;
  final SharedPassage passage;
}

/// Builds and reads reference-only Selah links.
///
/// Public web links use the GitHub Pages base path
/// `/selah_prototype_audio_13sep2026/` unless the app is already open on
/// another http(s) origin (a preview channel, for example). Recipients do
/// not need an account: the `ref` query is enough to open the passage.
class PassageShareLink {
  PassageShareLink._();

  static const String queryParameter = 'ref';

  /// Canonical public site for links shared from mobile and from tests.
  static const String publicWebOrigin = 'https://neiljaywarner.github.io';
  static const String githubPagesBasePath = '/selah_prototype_audio_13sep2026/';

  static const int _maxVerse = 176;

  static const Map<String, String> _labels = {
    'GEN': 'Gen',
    'EXO': 'Exod',
    'LEV': 'Lev',
    'NUM': 'Num',
    'DEU': 'Deut',
    'JOS': 'Josh',
    'JDG': 'Judg',
    'RUT': 'Ruth',
    '1SA': '1 Sam',
    '2SA': '2 Sam',
    '1KI': '1 Kgs',
    '2KI': '2 Kgs',
    '1CH': '1 Chr',
    '2CH': '2 Chr',
    'EZR': 'Ezra',
    'NEH': 'Neh',
    'EST': 'Esth',
    'JOB': 'Job',
    'PSA': 'Psalm',
    'PRO': 'Prov',
    'ECC': 'Eccl',
    'SNG': 'Song',
    'ISA': 'Isa',
    'JER': 'Jer',
    'LAM': 'Lam',
    'EZK': 'Ezek',
    'DAN': 'Dan',
    'HOS': 'Hos',
    'JOL': 'Joel',
    'AMO': 'Amos',
    'OBA': 'Obad',
    'JON': 'Jonah',
    'MIC': 'Mic',
    'NAM': 'Nah',
    'HAB': 'Hab',
    'ZEP': 'Zeph',
    'HAG': 'Hag',
    'ZEC': 'Zech',
    'MAL': 'Mal',
    'MAT': 'Matt',
    'MRK': 'Mark',
    'LUK': 'Luke',
    'JHN': 'John',
    'ACT': 'Acts',
    'ROM': 'Rom',
    '1CO': '1 Cor',
    '2CO': '2 Cor',
    'GAL': 'Gal',
    'EPH': 'Eph',
    'PHP': 'Phil',
    'COL': 'Col',
    '1TH': '1 Thess',
    '2TH': '2 Thess',
    '1TI': '1 Tim',
    '2TI': '2 Tim',
    'TIT': 'Titus',
    'PHM': 'Phlm',
    'HEB': 'Heb',
    'JAS': 'Jas',
    '1PE': '1 Pet',
    '2PE': '2 Pet',
    '1JN': '1 John',
    '2JN': '2 John',
    '3JN': '3 John',
    'JUD': 'Jude',
    'REV': 'Rev',
  };

  /// `?ref=` from a web URL, or null when this URI is not a share link.
  static String? refFromUri(Uri uri) {
    final raw = uri.queryParameters[queryParameter];
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  static SharedPassage? tryParse(String input) {
    final normalized = _normalize(input);
    if (normalized == null) return null;

    final match = RegExp(
      r'^(?<book>.+?) (?<chapter>\d+)(?::(?<start>\d+)(?:-(?<end>\d+))?)?$',
    ).firstMatch(normalized);
    if (match == null) return null;

    final book = BibleCanon.findExactBook(match.namedGroup('book')!);
    if (book == null) return null;

    final chapter = int.parse(match.namedGroup('chapter')!);
    if (chapter < 1 || chapter > book.totalChapters) return null;

    final startRaw = match.namedGroup('start');
    final endRaw = match.namedGroup('end');
    final start = startRaw == null ? null : int.parse(startRaw);
    final end = endRaw == null ? null : int.parse(endRaw);
    if (start != null && (start < 1 || start > _maxVerse)) return null;
    if (end != null && (start == null || end < start || end > _maxVerse)) {
      return null;
    }

    return SharedPassage(
      book: book,
      chapter: chapter,
      startVerse: start,
      endVerse: end,
      canonical: _format(book, chapter, start, end),
    );
  }

  /// Reference-only URL. Spaces become `+`, and the colon stays readable:
  /// `...?ref=1+Cor+13:4-7`.
  static String buildUrl(String reference, {Uri? page}) {
    final parsed = tryParse(reference);
    if (parsed == null) {
      throw ArgumentError.value(reference, 'reference', 'Not a shareable passage');
    }
    final token = parsed.canonical
        .replaceAll('%', '%25')
        .replaceAll(' ', '+')
        .replaceAll('&', '%26')
        .replaceAll('#', '%23')
        .replaceAll('?', '%3F');
    return '${_base(page)}?$queryParameter=$token';
  }

  static PassageSharePayload? tryPayload({
    required String reference,
    String? attribution,
    Uri? page,
  }) {
    final parsed = tryParse(reference);
    if (parsed == null) return null;
    final url = buildUrl(parsed.canonical, page: page);
    final shortAttribution = _safeAttribution(attribution);
    final lines = <String>[
      'Listen to ${parsed.canonical} in Selah',
      url,
      ?shortAttribution,
    ];
    return PassageSharePayload(
      reference: parsed.canonical,
      url: url,
      message: lines.join('\n'),
      attribution: shortAttribution,
    );
  }

  static String friendlyError(String raw) {
    final shown = _displayToken(raw);
    return 'Couldn\'t open that link. "$shown" is not a Bible passage Selah recognizes. Check the reference and try again.';
  }

  /// Reads plain references and the exact-ref JSON shape `{q, l}`.
  /// The shareable value is always the query, never a free-text label.
  static List<SavedShareItem> itemsFromSaved(Iterable<String> stored) {
    final items = <SavedShareItem>[];
    for (final raw in stored) {
      final parsed = tryParse(_queryFromStored(raw));
      if (parsed == null) continue;
      items.add(SavedShareItem(stored: raw, passage: parsed));
    }
    return items;
  }

  static String _queryFromStored(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{')) return trimmed;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final query = '${decoded['q'] ?? ''}'.trim();
        if (query.isNotEmpty) return query;
      }
    } catch (_) {
      // Legacy plain text that happens to start with a brace.
    }
    return trimmed;
  }

  static String? _normalize(String input) {
    var raw = input.trim();
    if (raw.isEmpty) return null;

    final asUri = Uri.tryParse(raw);
    if (asUri != null &&
        (asUri.scheme == 'http' || asUri.scheme == 'https') &&
        asUri.host.isNotEmpty) {
      final ref = refFromUri(asUri);
      if (ref == null) return null;
      raw = ref;
    }

    raw = raw.replaceAll('+', ' ');
    try {
      raw = Uri.decodeFull(raw);
    } catch (_) {}
    raw = raw.replaceAll('+', ' ');
    raw = raw.replaceAll(RegExp(r'[–—−]'), '-');
    raw = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return raw.isEmpty ? null : raw;
  }

  static String _displayToken(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'that link';
    final asUri = Uri.tryParse(trimmed);
    var shown = trimmed;
    if (asUri != null &&
        (asUri.scheme == 'http' || asUri.scheme == 'https') &&
        asUri.host.isNotEmpty) {
      shown = refFromUri(asUri) ?? trimmed;
    }
    shown = shown.replaceAll('+', ' ').trim();
    if (shown.length > 80) shown = '${shown.substring(0, 77)}...';
    return shown.isEmpty ? 'that link' : shown;
  }

  static String _format(BibleBook book, int chapter, int? start, int? end) {
    final label = _labels[book.code] ?? book.name;
    if (start == null) return '$label $chapter';
    if (end == null || end == start) return '$label $chapter:$start';
    return '$label $chapter:$start-$end';
  }

  /// Short copyright lines already shown in the player are fine.
  /// A paragraph, a line break, or a verse-length dump is not.
  static String? _safeAttribution(String? attribution) {
    final trimmed = attribution?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.length > 180) return null;
    return trimmed;
  }

  static String _base(Uri? page) {
    if (page != null &&
        (page.scheme == 'http' || page.scheme == 'https') &&
        page.host.isNotEmpty) {
      final defaultPort = page.scheme == 'https' ? 443 : 80;
      final port = page.hasPort && page.port != defaultPort ? ':${page.port}' : '';
      return '${page.scheme}://${page.host}$port${_directoryPath(page.path)}';
    }
    return '$publicWebOrigin$githubPagesBasePath';
  }

  static String _directoryPath(String path) {
    var cleaned = path;
    if (cleaned.endsWith('index.html')) {
      cleaned = cleaned.substring(0, cleaned.length - 'index.html'.length);
    }
    if (cleaned.isEmpty) return '/';
    if (!cleaned.endsWith('/')) {
      final slash = cleaned.lastIndexOf('/');
      cleaned = slash <= 0 ? '/' : cleaned.substring(0, slash + 1);
    }
    return cleaned;
  }
}
