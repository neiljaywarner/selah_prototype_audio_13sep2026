import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: the passage is read aloud
Future<void> thePassageIsReadAloud(WidgetTester tester) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(state.audioMode, AudioMode.tts);
  expect(state.currentChapter.audioStreamUrl, isEmpty);
  expect(state.activeExcerpt?.startVerse, 32);
  expect(state.activeExcerpt?.endVerse, 33);
  expect(state.currentChapter.bookCode, 'JHN');
  expect(state.currentChapter.chapterNumber, 16);
  expect(state.duration.inSeconds, lessThan(120));
}
