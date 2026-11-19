import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the play control
Future<void> iTapThePlayControl(WidgetTester tester) async {
  final play = find.byKey(const Key('play_passage_button'));
  expect(play, findsOneWidget);
  await tester.ensureVisible(play);
  await tester.tap(play);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
