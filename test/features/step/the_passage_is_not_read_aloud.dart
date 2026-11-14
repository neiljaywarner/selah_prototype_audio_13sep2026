import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: the passage is not read aloud
Future<void> thePassageIsNotReadAloud(WidgetTester tester) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(state.audioMode, AudioMode.narrator);
  expect(state.isPlaying, isFalse);
  expect(state.readAloudConfirmed, isFalse);
  expect(find.byKey(const Key('read_aloud_prompt')), findsNothing);
}
