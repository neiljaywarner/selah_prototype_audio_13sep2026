import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';

/// Usage: narrator loads finish without the device player
Future<void> narratorLoadsFinishWithoutTheDevicePlayer(
  WidgetTester tester,
) async {
  ChapterPlayerNotifier.debugBypassNativeAudio = true;
  addTearDown(() => ChapterPlayerNotifier.debugBypassNativeAudio = false);
}
