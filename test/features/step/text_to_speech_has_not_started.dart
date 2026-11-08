import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: text to speech has not started
Future<void> textToSpeechHasNotStarted(WidgetTester tester) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(state.audioMode, AudioMode.narrator);
  expect(state.isPlaying, isFalse);
  expect(state.readAloudPrompt, isTrue);
  expect(state.readAloudConfirmed, isFalse);
}
