import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import 'share_passage_harness.dart';

/// Usage: the next narrator load reports {'17'} seconds
///
/// The widget harness does not finish the native player load, so this records
/// the clip length at the same moment production would learn it from the file.
Future<void> theNextNarratorLoadReportsSeconds(
  WidgetTester tester,
  String seconds,
) async {
  final duration = Duration(seconds: int.parse(seconds));
  SharePassageWorld.narratorDurationMicros = duration.inMicroseconds;
  ChapterPlayerNotifier.debugOnAudioLoad = () async {
    final notifier = ProviderScope.containerOf(
      tester.element(find.byType(ChapterPlayerScreen)),
    ).read(chapterPlayerProvider.notifier);
    final current = notifier.state;
    notifier.state = current.copyWith(
      isLoading: false,
      isPlaying: false,
      duration: duration,
      position: Duration.zero,
    );
  };
  addTearDown(() => ChapterPlayerNotifier.debugOnAudioLoad = null);
}
