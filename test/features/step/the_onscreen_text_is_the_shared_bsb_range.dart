import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: the on-screen text is the shared BSB range {'Rest in God alone, O my soul'}
Future<void> theOnscreenTextIsTheSharedBsbRange(WidgetTester tester, String wording) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(
    find.textContaining(wording),
    findsWidgets,
    reason:
        'heading=${state.currentChapter.reference} '
        'mode=${state.audioMode} loading=${state.isLoading} '
        'url=${state.currentChapter.audioStreamUrl} '
        'error=${state.lastError} notice=${state.infoNotice} '
        'text=${state.currentChapter.textContent}',
  );
}
