import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: listening session chrome is shown
Future<void> listeningSessionChromeIsShown(WidgetTester tester) async {
  expect(find.textContaining('Human Narrator'), findsOneWidget);
  expect(find.textContaining('Loop 1 of 3'), findsOneWidget);
  expect(find.byKey(const Key('player_attribution_button')), findsOneWidget);
  expect(find.byKey(const Key('cycle_repetitions_chip')), findsOneWidget);
}
