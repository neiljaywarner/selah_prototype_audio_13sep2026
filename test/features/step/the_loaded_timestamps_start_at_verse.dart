import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: the loaded timestamps start at verse {4}
Future<void> theLoadedTimestampsStartAtVerse(WidgetTester tester, int verse) async {
  final timestamps = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider.notifier).currentTimestampsForTest;
  expect(timestamps, isNotNull);
  expect(timestamps!.first.verse, verse);
}
