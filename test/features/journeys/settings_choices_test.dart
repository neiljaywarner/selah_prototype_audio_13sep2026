import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import 'step/quiet_player_steps.dart';

void main() {
  testWidgets('a listener can choose seven repetitions and open prayer feedback', (tester) async {
    await thePlayerIsOpenWithoutAnEsvKey(tester);
    await iOpenMeditationSettings(tester);
    expect(find.text('CHAPTER REPETITIONS'), findsOneWidget);
    expect(find.text('7x'), findsOneWidget);

    await tester.tap(find.text('7x'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ChapterPlayerScreen));
    expect(ProviderScope.containerOf(context).read(chapterPlayerProvider).repetitions, 7);

    await tester.ensureVisible(find.text('10s'));
    await tester.tap(find.text('10s'));
    await tester.pumpAndSettle();
    expect(ProviderScope.containerOf(context).read(chapterPlayerProvider).pauseGapSeconds, 10);

    await tester.ensureVisible(find.text('Karaoke Text Highlighting'));
    await tester.tap(find.text('Karaoke Text Highlighting'));
    await tester.pumpAndSettle();
    expect(ProviderScope.containerOf(context).read(chapterPlayerProvider).karaokeEnabled, isFalse);

    await tester.ensureVisible(find.byTooltip('About Preview & Experimental Features'));
    await tester.tap(find.byTooltip('About Preview & Experimental Features'));
    await tester.pumpAndSettle();
    expect(find.text('Preview & Beta Features'), findsOneWidget);
    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prayer, Reflection & Feedback'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Loving it'), findsWidgets);
    await speechHasNotStarted(tester);
  });
}
