import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads a public-domain verse range (BSB or WEB) when it is not already
/// in the offline bank.
///
/// Helloao publishes the Berean Standard Bible and the World English Bible.
/// This is only used for those two translations. ESV stays on Crossway.
final publicDomainPassageTextProvider = Provider<PublicDomainPassageText>(
  (ref) => PublicDomainPassageText(),
);

class PublicDomainPassageText {
  PublicDomainPassageText({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: _timeout,
                receiveTimeout: _timeout,
              ),
            );

  final Dio _dio;

  static const _timeout = Duration(seconds: 6);

  Future<String?> fetchRange({
    required String translation,
    required String bookCode,
    required int chapterNumber,
    required int startVerse,
    required int endVerse,
  }) async {
    final helloAoId = helloAoTranslationId(translation);
    if (helloAoId == null) return null;
    if (startVerse < 1 || endVerse < startVerse) return null;

    try {
      final res = await _dio.get<dynamic>(
        'https://bible.helloao.org/api/$helloAoId/${bookCode.toUpperCase()}/$chapterNumber.json',
      );
      return textFromHelloAoBody(
        res.data,
        startVerse: startVerse,
        endVerse: endVerse,
      );
    } catch (_) {
      return null;
    }
  }

  /// Helloao ids differ from Selah's translation codes. WEB is `eng_web`.
  static String? helloAoTranslationId(String translation) {
    switch (translation.trim().toUpperCase()) {
      case 'BSB':
        return 'BSB';
      case 'WEB':
        return 'eng_web';
      default:
        return null;
    }
  }

  /// Joins [startVerse] through [endVerse] from a Helloao chapter document.
  /// Returns null unless every verse in the range is present.
  static String? textFromHelloAoBody(
    Object? body, {
    required int startVerse,
    required int endVerse,
  }) {
    if (body is! Map) return null;
    final chapter = body['chapter'];
    if (chapter is! Map) return null;
    final content = chapter['content'];
    if (content is! List) return null;

    final byVerse = <int, String>{};
    for (final item in content) {
      if (item is! Map || item['type'] != 'verse') continue;
      final number = item['number'];
      if (number is! int) continue;
      final piece = _joinContent(item['content']).trim();
      if (piece.isNotEmpty) byVerse[number] = piece;
    }

    final parts = <String>[];
    for (var verse = startVerse; verse <= endVerse; verse++) {
      final piece = byVerse[verse];
      if (piece == null) return null;
      parts.add(piece);
    }
    return parts.join(' ');
  }

  static String _joinContent(Object? content) {
    if (content is! List) return '';
    final pieces = <String>[];
    for (final part in content) {
      if (part is String) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) pieces.add(trimmed);
      } else if (part is Map) {
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) pieces.add(text.trim());
      }
    }
    return pieces.join(' ');
  }
}
