import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I can start playback
Future<void> iCanStartPlayback(WidgetTester tester) async {
  final play = find.byKey(const Key('play_passage_button'));
  expect(play, findsOneWidget);
  final button = tester.widget<GestureDetector>(play);
  expect(button.onTap, isNotNull, reason: 'Play should be available for a shared passage');
  await tester.ensureVisible(play);
  await tester.tap(play);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  );
  final state = container.read(chapterPlayerProvider);
  expect(state.currentChapter.bookCode, '1CO');
  expect(state.currentChapter.chapterNumber, 13);
  expect(
    state.isPlaying || state.isLoading || state.currentChapter.audioStreamUrl.isNotEmpty,
    isTrue,
    reason:
        'Playback should start for the shared range '
        '(playing=${state.isPlaying}, loading=${state.isLoading}, '
        'url=${state.currentChapter.audioStreamUrl}, mode=${state.audioMode}, '
        'error=${state.lastError}, notice=${state.infoNotice})',
  );
  final error = state.lastError ?? '';
  expect(error.toLowerCase().contains('sign in'), isFalse);
  expect(error.toLowerCase().contains('log in'), isFalse);
}
