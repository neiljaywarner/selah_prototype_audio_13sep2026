import 'package:flutter_test/flutter_test.dart';

/// Usage: the human narrator chip is hidden
Future<void> theHumanNarratorChipIsHidden(WidgetTester tester) async {
  expect(find.textContaining('Human Narrator'), findsNothing);
}
