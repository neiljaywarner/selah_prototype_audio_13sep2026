import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I am asked before the passage is read aloud
Future<void> iAmAskedBeforeThePassageIsReadAloud(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.byKey(const Key('read_aloud_prompt')), findsOneWidget);
  expect(find.text('Read aloud'), findsOneWidget);
  expect(find.text('Not now'), findsOneWidget);
}
