import 'package:flutter_test/flutter_test.dart';

/// Usage: I do not see the curated wording {'My soul finds rest in God alone'}
Future<void> iDoNotSeeTheCuratedWording(WidgetTester tester, String wording) async {
  expect(find.textContaining(wording), findsNothing);
}
