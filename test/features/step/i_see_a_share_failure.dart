import 'package:flutter_test/flutter_test.dart';

/// Usage: I see a share failure
Future<void> iSeeAShareFailure(WidgetTester tester) async {
  expect(find.textContaining("Couldn't share that passage"), findsOneWidget);
  expect(find.textContaining('Link ready to share'), findsNothing);
}
