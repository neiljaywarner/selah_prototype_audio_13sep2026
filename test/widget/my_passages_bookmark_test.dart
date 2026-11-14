import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import '../features/step/share_passage_harness.dart';
import '../features/step/the_passage_playing_is.dart';

void main() {
  testWidgets('a featured chip replaces stale search text before bookmarking', (tester) async {
    await thePassagePlayingIs(tester, '1 Cor 13:4-7');
    await tester.enterText(find.byType(TextField).first, 'John 3:16');
    await tester.pump();

    final matt = find.text('Matt 11:28–30');
    await tester.ensureVisible(matt.first);
    await tester.tap(matt.first);
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_current_passage')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Saved "Matt 11:28-30" to My passages'), findsOneWidget);
    expect(find.textContaining('John 3:16'), findsNothing);
  });

  testWidgets('a saved single verse does not open the curated range', (tester) async {
    SharePassageWorld.reset();
    SharePassageWorld.savedPassages = const ['1 Cor 13:5'];
    await pumpSharePassageApp(tester);

    final chip = find.text('1 Cor 13:5');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();

    final state = ProviderScope.containerOf(
      tester.element(find.byType(ChapterPlayerScreen)),
    ).read(chapterPlayerProvider);
    expect(state.activeExcerpt?.startVerse, 5);
    expect(state.activeExcerpt?.endVerse, 5);
    expect(state.currentChapter.reference, '1 Cor 13:5');
  });

  testWidgets('starting playback records the passage and a second tap does not add another', (tester) async {
    SharePassageWorld.reset();
    await pumpSharePassageApp(tester);

    await tester.tap(find.byKey(const Key('play_passage_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChapterPlayerScreen)),
    );
    expect(container.read(userPreferencesProvider).lastPlayedQuery, '1 Cor 13:4-7');
    expect(
      container.read(userPreferencesProvider).recentPassages.map((p) => p.query),
      ['1 Cor 13:4-7'],
    );
  });
}
