import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I tap the passage chip {'Matt 11:28–30'}
Future<void> iTapThePassageChip(WidgetTester tester, String label) async {
  final chip = find.byWidgetPredicate((widget) {
    if (widget is! Text || widget.data != label) return false;
    return widget.style?.fontSize == 12;
  });
  expect(
    chip,
    findsOneWidget,
    reason: 'Passage chip "$label" should be on screen',
  );
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    final state = ProviderScope.containerOf(
      tester.element(find.byType(ChapterPlayerScreen)),
    ).read(chapterPlayerProvider);
    if (!state.isLoading) break;
  }
}
