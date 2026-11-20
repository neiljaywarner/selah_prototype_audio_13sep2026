import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: I tap the play control
Future<void> iTapThePlayControl(WidgetTester tester) async {
  final play = find.byKey(const Key('play_passage_button'));
  expect(play, findsOneWidget);
  await tester.ensureVisible(play);
  await tester.tap(play);
  await tester.pump();
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (SharePassageWorld.narratorPlayerCalls.contains('play')) break;
  }
}
