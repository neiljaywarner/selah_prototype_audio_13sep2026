import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I route to {'Psalm 62:5-7'}
Future<void> iRouteTo(WidgetTester tester, String reference) async {
  final parsed = PassageShareLink.tryParse(reference);
  expect(parsed, isNotNull, reason: 'Test reference should be shareable');
  final passage = parsed!;
  final excerpt = passage.startVerse == null
      ? PassageExcerpt.forChapter(passage.book.code, passage.chapter)
      : PassageExcerpt.customExcerpt(
          bookCode: passage.book.code,
          chapterNumber: passage.chapter,
          startVerse: passage.startVerse!,
          endVerse: passage.endVerse ?? passage.startVerse!,
          displayTitle: passage.canonical,
        );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  );
  unawaited(
    container.read(chapterPlayerProvider.notifier).routeAndPlayChapter(
          bookCode: passage.book.code,
          chapterNumber: passage.chapter,
          bookName: passage.book.name,
          excerpt: excerpt,
        ),
  );
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.textContaining(passage.canonical).evaluate().isNotEmpty) break;
  }
}
