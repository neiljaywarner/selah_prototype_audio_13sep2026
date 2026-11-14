import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import 'share_passage_harness.dart';

/// Usage: the passage playing is {'Psalm 62:5-7'} in {'ESV'}
Future<void> thePassagePlayingIsIn(
  WidgetTester tester,
  String reference,
  String translation,
) async {
  SharePassageWorld.reset();
  SharePassageWorld.forcedTranslation = translation;
  await pumpSharePassageApp(tester);
  final parsed = PassageShareLink.tryParse(reference);
  expect(parsed, isNotNull, reason: 'Test reference should be shareable');
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  );
  container.read(chapterPlayerProvider.notifier).presentSharedPassage(parsed!);
  await tester.pump();
}
