import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I play the shared passage
Future<void> iPlayTheSharedPassage(WidgetTester tester) async {
  final play = find.byKey(const Key('play_passage_button'));
  expect(play, findsOneWidget);
  await tester.ensureVisible(play);
  await tester.tap(play);
  await tester.pump();

  final screen = find.byType(ChapterPlayerScreen);
  final container = ProviderScope.containerOf(tester.element(screen));
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (!container.read(chapterPlayerProvider).isLoading) break;
  }
}
