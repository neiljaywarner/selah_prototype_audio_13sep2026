import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the player is not blank
Future<void> thePlayerIsNotBlank(WidgetTester tester) async {
  expect(find.byType(Scaffold), findsWidgets);
  expect(find.text('SELAH'), findsOneWidget);
  expect(find.textContaining('does not open a passage'), findsOneWidget);
  expect(find.byKey(const Key('current_passage_reference')), findsOneWidget);
}
