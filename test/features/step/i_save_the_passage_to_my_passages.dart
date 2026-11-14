import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I save the passage to My passages
Future<void> iSaveThePassageToMyPassages(WidgetTester tester) async {
  final save = find.byKey(const Key('save_current_passage'));
  expect(save, findsOneWidget);
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.text('Saved "1 Cor 13:4-7" to My passages'), findsOneWidget);
}
