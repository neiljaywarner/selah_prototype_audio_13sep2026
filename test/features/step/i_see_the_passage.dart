import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I see the passage {'1 Cor 13:4-7'}
Future<void> iSeeThePassage(WidgetTester tester, String reference) async {
  expect(find.text(reference), findsWidgets);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  );
  final state = container.read(chapterPlayerProvider);
  final parsed = PassageShareLink.tryParse(state.currentChapter.reference);
  expect(parsed?.canonical, reference);
  expect(state.currentChapter.bookCode, isNotEmpty);
  expect(state.lastError, isNull);
}
