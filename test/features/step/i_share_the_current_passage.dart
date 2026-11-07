import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I share the current passage
Future<void> iShareTheCurrentPassage(WidgetTester tester) async {
  final button = find.byKey(const Key('share_current_passage'));
  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
