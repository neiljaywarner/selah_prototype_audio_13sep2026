import 'package:flutter_test/flutter_test.dart';

/// Usage: the human narrator chip is shown
Future<void> theHumanNarratorChipIsShown(WidgetTester tester) async {
  expect(find.textContaining('Human Narrator'), findsOneWidget);
}
