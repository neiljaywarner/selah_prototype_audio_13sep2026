import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: playback has started
Future<void> playbackHasStarted(WidgetTester tester) async {
  final calls = SharePassageWorld.narratorPlayerCalls;
  final loadAt = calls.indexOf('load');
  final playAt = calls.lastIndexOf('play');
  expect(loadAt, greaterThanOrEqualTo(0), reason: 'Narrator audio should be loaded first');
  expect(
    playAt,
    greaterThan(loadAt),
    reason: 'Play should ask the loaded narrator source to start. Calls: $calls',
  );
  final source = SharePassageWorld.loadedNarratorSource ?? '';
  expect(
    source.contains('MAT_11') || source.contains('assets/audio'),
    isTrue,
    reason: 'Play should follow the loaded narrator source, saw "$source"',
  );
  expect(SharePassageWorld.ttsSpeakCalls, 0);
}
