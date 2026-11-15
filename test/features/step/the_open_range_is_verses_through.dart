import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: the open range is verses {'4'} through {'7'}
Future<void> theOpenRangeIsVersesThrough(
  WidgetTester tester,
  String start,
  String end,
) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  final excerpt = state.activeExcerpt;
  expect(
    excerpt,
    isNotNull,
    reason: 'Reopening a range should keep an excerpt',
  );
  expect(excerpt!.startVerse, int.parse(start));
  expect(excerpt.endVerse, int.parse(end));
  expect(state.currentChapter.reference, '1 Cor 13:4-7');
}
