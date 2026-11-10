import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I load the bundled chapter {'PSA'} {62}
Future<void> iLoadTheBundledChapter(
  WidgetTester tester,
  String bookCode,
  int chapterNumber,
) async {
  final notifier = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider.notifier);
  final pending = notifier.loadChapter(
    ChapterInfo(
      bookCode: bookCode,
      bookName: bookCode,
      chapterNumber: chapterNumber,
      audioStreamUrl: 'assets/audio/BSB/${bookCode}_$chapterNumber.mp3',
      textContent: '$bookCode $chapterNumber',
    ),
  );
  pending.ignore();
  await tester.pump();
}
