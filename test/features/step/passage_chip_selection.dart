import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Indigo fill used when a passage chip is the loaded passage.
const Color passageChipSelectedColor = Color(0xFF6366F1);

/// Dark fill used when a passage chip is not the loaded passage.
const Color passageChipIdleColor = Color(0xFF1E1B4B);

bool passageChipLooksSelected(WidgetTester tester, String label) {
  final decoration = _chipDecoration(tester, label);
  return decoration.color == passageChipSelectedColor;
}

String passageChipSelectionReason(
  WidgetTester tester,
  String label, {
  required bool expectedSelected,
}) {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  final chapter = state.currentChapter;
  final color = _chipDecoration(tester, label).color;
  return 'Chip "$label" color=$color, expected selected=$expectedSelected. '
      'Loaded reference="${chapter.reference}" displayTitle="${chapter.displayTitle}".';
}

BoxDecoration _chipDecoration(WidgetTester tester, String label) {
  final chip = find.byWidgetPredicate((widget) {
    if (widget is! Text || widget.data != label) return false;
    return widget.style?.fontSize == 12;
  });
  expect(
    chip,
    findsOneWidget,
    reason: 'Passage chip "$label" should be on screen',
  );
  final containers = find.ancestor(
    of: chip,
    matching: find.byType(AnimatedContainer),
  );
  expect(containers, findsWidgets);
  for (final element in containers.evaluate()) {
    final decoration = (element.widget as AnimatedContainer).decoration;
    if (decoration is BoxDecoration &&
        (decoration.color == passageChipSelectedColor ||
            decoration.color == passageChipIdleColor)) {
      return decoration;
    }
  }
  fail('No passage-chip decoration found for "$label"');
}
