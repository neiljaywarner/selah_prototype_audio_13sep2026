import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: playback stops continue
Future<void> playbackStopsContinue(WidgetTester tester) async {
  SharePassageWorld.releasePlaybackStops();
  await tester.pump();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
