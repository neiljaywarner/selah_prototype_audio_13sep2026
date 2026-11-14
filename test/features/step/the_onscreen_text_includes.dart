import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import 'share_passage_harness.dart';

/// Usage: the on-screen text includes {'Look, an hour is coming'}
Future<void> theOnscreenTextIncludes(WidgetTester tester, String wording) async {
  final state = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider);
  expect(
    find.textContaining(wording),
    findsWidgets,
    reason:
        'heading=${state.currentChapter.reference} '
        'translation=${state.activeTranslation} '
        'mode=${state.audioMode} loading=${state.isLoading} '
        'error=${state.lastError} notice=${state.infoNotice} '
        'esv=${SharePassageWorld.esvQueries} '
        'text=${state.currentChapter.textContent}',
  );
}
