import 'package:flutter_test/flutter_test.dart';

/// Usage: I am not asked to sign in
Future<void> iAmNotAskedToSignIn(WidgetTester tester) async {
  expect(find.textContaining('Sign in'), findsNothing);
  expect(find.textContaining('Log in'), findsNothing);
  expect(find.textContaining('Create account'), findsNothing);
  expect(find.text('SELAH'), findsOneWidget);
}
