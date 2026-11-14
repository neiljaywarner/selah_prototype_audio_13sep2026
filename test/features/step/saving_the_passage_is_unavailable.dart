import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: saving the passage is unavailable
Future<void> savingThePassageIsUnavailable(WidgetTester tester) async {
  final button = tester.widget<IconButton>(find.byKey(const Key('save_current_passage')));
  expect(button.onPressed, isNull);
}
