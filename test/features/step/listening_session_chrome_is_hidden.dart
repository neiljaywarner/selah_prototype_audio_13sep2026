import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: listening session chrome is hidden
Future<void> listeningSessionChromeIsHidden(WidgetTester tester) async {
  expect(find.textContaining('Human Narrator'), findsNothing);
  expect(find.textContaining('Crossway'), findsNothing);
  expect(find.textContaining('API.Bible'), findsNothing);
  expect(find.textContaining('Loop '), findsNothing);
  expect(find.byKey(const Key('player_attribution_button')), findsNothing);
  expect(find.byKey(const Key('cycle_repetitions_chip')), findsNothing);
}
