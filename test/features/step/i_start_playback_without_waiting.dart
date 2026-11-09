import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I start playback without waiting
Future<void> iStartPlaybackWithoutWaiting(WidgetTester tester) async {
  final play = find.byKey(const Key('play_passage_button'));
  expect(play, findsOneWidget);
  await tester.ensureVisible(play);
  await tester.tap(play);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
