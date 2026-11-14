import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: the heading stays on {'John 16:32-33'}
Future<void> theHeadingStaysOn(WidgetTester tester, String reference) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  final parsed = PassageShareLink.tryParse(state.currentChapter.reference);
  expect(parsed?.canonical, reference, reason: 'heading was ${state.currentChapter.reference}');
}
