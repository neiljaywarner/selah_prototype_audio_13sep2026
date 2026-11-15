import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I open {'1 Cor 13:4-7'} from My passages
Future<void> iOpenFromMyPassages(WidgetTester tester, String reference) async {
  final row = find.byKey(Key('my_passage_$reference'));
  expect(row, findsOneWidget);
  await tester.tap(row);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
