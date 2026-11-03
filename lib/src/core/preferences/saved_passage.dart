import 'dart:convert';

import '../../features/meditation/domain/chapter_info.dart';
import '../../features/meditation/domain/passage_excerpt.dart';
import '../esv/esv_passage_policy.dart';

/// Outcome of an explicit bookmark into My passages.
enum SavePassageResult { saved, alreadySaved, full, unavailable }

/// A passage the user can replay by its exact reference.
///
/// [query] is the ESV-ready string (`1 Cor 13:4-7`). [label] is what the chip
/// shows and is the only field rename changes.
class SavedPassage {
  const SavedPassage({required this.query, required this.label});

  final String query;
  final String label;

  String encode() => jsonEncode(<String, String>{'q': query, 'l': label});

  /// Accepts the JSON form and the legacy plain-text recents list.
  static SavedPassage? tryDecode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          final query = PassageQuery.canonicalize('${decoded['q'] ?? ''}');
          if (query.isEmpty) return null;
          final labelRaw = '${decoded['l'] ?? ''}'.trim();
          return SavedPassage(
            query: query,
            label: labelRaw.isEmpty ? query : labelRaw,
          );
        }
      } catch (_) {
        // Not JSON; treat the whole string as a legacy reference.
      }
    }
    final query = PassageQuery.canonicalize(trimmed);
    if (query.isEmpty) return null;
    return SavedPassage(query: query, label: trimmed);
  }
}

/// Normalizes typed references so a saved range round-trips through ESV.
class PassageQuery {
  static final RegExp _verseOrRange = RegExp(r'^.+\s+\d+:\d+(-\d+)?$');
  static final RegExp _chapter = RegExp(r'^.+\s+\d+$');
  static final RegExp _spacedRange = RegExp(r'(\d+)\s*-\s*(\d+)$');

  /// Collapses whitespace and unicode dashes. `1 Cor 13:4 – 7` → `1 Cor 13:4-7`.
  static String canonicalize(String raw) {
    var normalized = EsvPassagePolicy.normalizePassageQuery(raw);
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    normalized = normalized.replaceAllMapped(_spacedRange, (m) => '${m[1]}-${m[2]}');
    return normalized;
  }

  static bool isVerseOrRange(String canonical) => _verseOrRange.hasMatch(canonical);

  static bool looksLikePassage(String canonical) =>
      canonical.isNotEmpty && (isVerseOrRange(canonical) || _chapter.hasMatch(canonical));
}

/// Reference the bookmark button should persist.
///
/// A typed verse or range wins over the chapter currently loaded, so
/// `1 Cor 13:4-7` is not stored as `1 Corinthians 13`.
String resolvePassageToSave({
  required String fieldText,
  required ChapterInfo chapter,
  PassageExcerpt? activeExcerpt,
}) {
  final field = PassageQuery.canonicalize(fieldText);
  if (PassageQuery.looksLikePassage(field)) return field;

  if (activeExcerpt != null) {
    final fromExcerpt = PassageQuery.canonicalize(activeExcerpt.toEsvPassageQuery());
    if (fromExcerpt.isNotEmpty) return fromExcerpt;
  }

  final fromChapter = esvPassageQueryFor(chapter, excerpt: activeExcerpt);
  if (fromChapter != null) {
    final normalized = PassageQuery.canonicalize(fromChapter);
    if (normalized.isNotEmpty) return normalized;
  }

  final title = chapter.displayTitle;
  if (title != null && title.trim().isNotEmpty) {
    return PassageQuery.canonicalize(title);
  }
  return PassageQuery.canonicalize('${chapter.bookName} ${chapter.chapterNumber}');
}
