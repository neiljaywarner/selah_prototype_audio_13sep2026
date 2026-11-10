import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

ChapterInfo _bundled(String bookCode, int chapterNumber) => ChapterInfo(
      bookCode: bookCode,
      bookName: bookCode,
      chapterNumber: chapterNumber,
      audioStreamUrl: 'assets/audio/BSB/${bookCode}_$chapterNumber.mp3',
      textContent: '$bookCode $chapterNumber',
    );

/// Usage: an older audio load is overtaken by {'1CO'} {13}
Future<void> anOlderAudioLoadIsOvertakenBy(
  WidgetTester tester,
  String bookCode,
  int chapterNumber,
) async {
  final notifier = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  ).read(chapterPlayerProvider.notifier);
  var handedOff = false;
  ChapterPlayerNotifier.debugOnAudioLoad = () async {
    if (handedOff) return;
    handedOff = true;
    final newer = notifier.loadChapter(_bundled(bookCode, chapterNumber));
    newer.ignore();
  };
  addTearDown(() => ChapterPlayerNotifier.debugOnAudioLoad = null);
  final older = notifier.loadChapter(_bundled('PSA', 62));
  older.ignore();
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
