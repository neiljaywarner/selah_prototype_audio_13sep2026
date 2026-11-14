import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: playback is the shared range and not the full chapter
Future<void> playbackIsTheSharedRangeAndNotTheFullChapter(
  WidgetTester tester,
) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  );
  final state = container.read(chapterPlayerProvider);
  expect(state.currentChapter.reference, 'Psalm 62:5-7');
  expect(state.currentChapter.audioStreamUrl, isNot(contains('PSA_62')));
  expect(state.currentChapter.audioStreamUrl, isEmpty);
  expect(
    state.currentChapter.textContent,
    contains('Rest in God alone, O my soul'),
  );
  expect(
    state.currentChapter.textContent,
    isNot(contains('My soul finds rest in God alone')),
  );
  expect(state.audioMode, AudioMode.narrator);
  expect(state.isPlaying, isFalse);
  expect(state.infoNotice, contains('did not start a synthetic voice'));
  expect(state.activeExcerpt?.startVerse, 5);
  expect(state.activeExcerpt?.endVerse, 7);
}
