import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: playback stops are held
Future<void> playbackStopsAreHeld(WidgetTester tester) async {
  SharePassageWorld.holdPlaybackStops();
}
