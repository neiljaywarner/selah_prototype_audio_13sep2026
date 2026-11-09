import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I search for {'John 16:32-33'}
Future<void> iSearchFor(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  );
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    final player = container.read(chapterPlayerProvider);
    if (player.currentChapter.bookCode == 'VRS' &&
        player.currentChapter.displayTitle == query) {
      break;
    }
  }
}
