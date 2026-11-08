import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the heading stays {'Psalm 62:5-7'}
Future<void> theHeadingStays(WidgetTester tester, String reference) async {
  expect(find.byKey(const Key('current_passage_reference')), findsOneWidget);
  expect(find.text(reference), findsWidgets);
}
