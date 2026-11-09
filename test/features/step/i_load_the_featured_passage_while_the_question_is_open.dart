import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I load the featured passage {'1 Cor 13:4'} while the question is open
Future<void> iLoadTheFeaturedPassageWhileTheQuestionIsOpen(
  WidgetTester tester,
  String label,
) async {
  expect(find.byKey(const Key('read_aloud_prompt')), findsOneWidget);
  final chapter = kFeaturedChapters.firstWhere(
    (item) => (item.displayTitle ?? item.reference).contains(label),
  );
  final notifier = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider.notifier);
  final pending = notifier.loadChapter(chapter);
  pending.ignore();
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.textContaining('Love is patient').evaluate().isNotEmpty) break;
  }
}
