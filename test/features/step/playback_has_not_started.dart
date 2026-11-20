import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import 'share_passage_harness.dart';

/// Usage: playback has not started
Future<void> playbackHasNotStarted(WidgetTester tester) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(
    SharePassageWorld.narratorPlayerCalls,
    contains('load'),
    reason: 'The narrator source should be loaded before the listener decides to play',
  );
  expect(
    SharePassageWorld.narratorPlayerCalls,
    isNot(contains('play')),
    reason: 'A chip tap must not ask the narrator player to start',
  );
  expect(state.isPlaying, isFalse);
  expect(state.audioMode, AudioMode.narrator);
  expect(SharePassageWorld.ttsSpeakCalls, 0);
  expect(find.byIcon(Icons.pause_rounded), findsNothing);
}
