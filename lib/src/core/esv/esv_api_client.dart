import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/api_constants.dart';

/// One verse returned by the ESV API.
class EsvVerse {
  const EsvVerse({required this.reference, required this.text});

  final String reference;
  final String text;
}

/// Thin client for Crossway's ESV API v3 `GET /passage/text/`.
///
/// A range such as "1 Cor 13:4-7" is expanded and fetched one verse at a time
/// so each verse can be shown and narrated on its own. Same-chapter ranges
/// longer than [kEsvMaxSingleVerseLookups] are left as a single query so a
/// pasted chapter does not burn the 60 requests/minute budget. Ranges over
/// 500 verses are not sent (Crossway's per-request cap).
///
/// Chapter audio stays on API.Bible. This client does not cache text to disk.
class EsvApiClient {
  EsvApiClient({Dio? dio, String? apiKey})
    : _apiKey = sanitizeEnvSecret(apiKey ?? kEsvApiKey),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: kEsvBaseUrl,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              headers: {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;
  final String _apiKey;

  String get apiKey => _apiKey;
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Direct Crossway Hear-the-Word CDN URL for [query].
  ///
  /// Matches the `302 Location` target returned by `GET /v3/passage/audio/?q=...`
  /// (`https://audio.esv.org/hw/<encoded>.mp3`). Works directly in HTML5 `<audio>`
  /// on Web without custom HTTP headers or XHR CORS preflight errors.
  static String directHwAudioUrl(String query) {
    final normalized = query.trim().replaceAll(RegExp(r'[–—]'), '-');
    return 'https://audio.esv.org/hw/${Uri.encodeComponent(normalized)}.mp3';
  }

  /// Resolves a playable human narrator MP3 URL for [query].
  ///
  /// On Web (`isWeb: true`), browser `XMLHttpRequest` cannot stop at `302`
  /// (`followRedirects: false` is ignored) and fails CORS on `audio.esv.org`,
  /// while HTML5 `<audio>` cannot attach `Authorization` headers. Returning
  /// [directHwAudioUrl] allows `<audio>` to stream Crossway MP3s natively.
  Future<String?> resolvePassageAudioUrl(
    String query, {
    bool isWeb = kIsWeb,
  }) async {
    if (!isConfigured) return null;
    final normalized = query.trim().replaceAll(RegExp(r'[–—]'), '-');
    if (normalized.isEmpty) return null;
    if (isWeb) {
      return directHwAudioUrl(normalized);
    }
    return await fetchPassageAudioUrl(normalized) ?? directHwAudioUrl(normalized);
  }

  /// Resolves the direct human narrator MP3 URL for a passage query.
  /// Follows the redirects from api.esv.org to audio.esv.org.
  Future<String?> fetchPassageAudioUrl(String query) async {
    if (!isConfigured) return null;
    try {
      final res = await _dio.get<dynamic>(
        '/passage/audio/',
        queryParameters: <String, dynamic>{'q': query},
        options: Options(
          headers: {'Authorization': 'Token $_apiKey'},
          followRedirects: false,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );
      String? location = res.headers.value('location');
      if (location != null && location.isNotEmpty) {
        // Follow internal redirect on audio.esv.org if needed (e.g. /hw/ -> /hw/mq/)
        try {
          final res2 = await _dio.get<dynamic>(
            location,
            options: Options(
              headers: {'Authorization': 'Token $_apiKey'},
              followRedirects: false,
              validateStatus: (s) => s != null && s >= 200 && s < 400,
            ),
          );
          final loc2 = res2.headers.value('location');
          if (loc2 != null && loc2.isNotEmpty) {
            return loc2;
          }
        } catch (_) {}
        return location;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Book, chapter, start verse, end verse. Same chapter only.
  static final RegExp _range = RegExp(r'^(.+?)\s+(\d+):(\d+)\s*[-–—]\s*(\d+)$');

  /// Expands "1 Cor 13:4-7" into ["1 Cor 13:4", ..., "1 Cor 13:7"].
  /// A query that is not a same-chapter verse range is returned unchanged.
  static List<String> expandToSingleVerses(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final match = _range.firstMatch(trimmed);
    if (match == null) return [trimmed];

    final book = match.group(1)!;
    final chapter = match.group(2)!;
    final start = int.parse(match.group(3)!);
    final end = int.parse(match.group(4)!);
    final count = end - start + 1;
    if (end < start || count > 500 || count > kEsvMaxSingleVerseLookups) {
      return [trimmed];
    }
    return [
      for (var verse = start; verse <= end; verse++) '$book $chapter:$verse',
    ];
  }

  /// "1 Corinthians 13:4" + "1 Corinthians 13:7" → "1 Corinthians 13:4–7".
  static String joinedReference(List<EsvVerse> verses) {
    if (verses.isEmpty) return '';
    if (verses.length == 1) return verses.first.reference;
    final last = verses.last.reference;
    final colon = last.lastIndexOf(':');
    final endVerse = colon >= 0 ? last.substring(colon + 1) : last;
    return '${verses.first.reference}–$endVerse';
  }

  /// Fetches one reference. Returns null when ESV has no passage text.
  Future<EsvVerse?> fetchVerse(String query) async {
    final res = await _dio.get<dynamic>(
      '/passage/text/',
      queryParameters: <String, dynamic>{
        'q': query,
        'include-passage-references': false,
        'include-verse-numbers': false,
        'include-first-verse-numbers': false,
        'include-footnotes': false,
        'include-footnote-body': false,
        'include-headings': false,
        'include-short-copyright': false,
        'include-copyright': false,
      },
      options: Options(headers: {'Authorization': 'Token $_apiKey'}),
    );
    final data = res.data;
    if (res.statusCode != 200 || data is! Map) return null;
    final passages = data['passages'];
    if (passages is! List || passages.isEmpty || passages.first is! String) {
      return null;
    }
    final text = (passages.first as String)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return null;
    final canonical = data['canonical'];
    return EsvVerse(
      reference: canonical is String && canonical.trim().isNotEmpty
          ? canonical.trim()
          : query,
      text: text,
    );
  }

  /// Fetches [query] verse by verse. An incomplete range returns an empty list
  /// so the caller can fall back to bible-api.com instead of skipping a verse.
  Future<List<EsvVerse>> fetchVerseByVerse(String query) async {
    final expanded = expandToSingleVerses(query);
    if (expanded.isEmpty) return const [];
    final out = <EsvVerse>[];
    for (final single in expanded) {
      final verse = await fetchVerse(single);
      if (verse == null) return const [];
      out.add(verse);
    }
    return out;
  }
}
