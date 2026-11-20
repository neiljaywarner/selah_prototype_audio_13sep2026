import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: the duration bar shows {'00:17'}
Future<void> theDurationBarShows(WidgetTester tester, String label) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(
    _durationLabel(tester),
    label,
    reason:
        'loading=${state.isLoading} playing=${state.isPlaying} '
        'duration=${state.duration} position=${state.position} '
        'url=${state.currentChapter.audioStreamUrl} '
        'mode=${state.audioMode} error=${state.lastError} notice=${state.infoNotice} '
        'ref=${state.currentChapter.reference}',
  );
}

String _durationLabel(WidgetTester tester) {
  final times = find.byWidgetPredicate((widget) {
    return widget is Text &&
        RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data ?? '');
  });
  expect(
    times,
    findsNWidgets(2),
    reason: 'Position and duration labels should both be on screen',
  );
  final labels = times
      .evaluate()
      .map((element) => (element.widget as Text).data!)
      .toList();
  return labels.last;
}
