import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import 'share_passage_harness.dart';

/// Usage: read aloud did not start
Future<void> readAloudDidNotStart(WidgetTester tester) async {
  expect(SharePassageWorld.ttsSpeakCalls, 0);
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(state.readAloudPrompt, isFalse);
  expect(state.readAloudConfirmed, isFalse);
}
