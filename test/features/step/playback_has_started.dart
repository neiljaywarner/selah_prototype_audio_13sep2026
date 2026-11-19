import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import 'share_passage_harness.dart';

/// Usage: playback has started
Future<void> playbackHasStarted(WidgetTester tester) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(
    state.isPlaying || state.isLoading,
    isTrue,
    reason: 'The play control should start narrator playback',
  );
  expect(state.audioMode, isNot(AudioMode.tts));
  expect(SharePassageWorld.ttsSpeakCalls, 0);
}
