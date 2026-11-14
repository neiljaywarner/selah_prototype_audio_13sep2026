import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: My passages lists {'1 Cor 13:4-7'}
Future<void> myPassagesLists(WidgetTester tester, String reference) async {
  final open = find.byKey(const Key('open_my_passages'));
  await tester.ensureVisible(open);
  await tester.tap(open);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byKey(const Key('my_passages_sheet')), findsOneWidget);
  expect(find.byKey(Key('my_passage_$reference')), findsOneWidget);
  expect(find.text(reference), findsWidgets);
}
