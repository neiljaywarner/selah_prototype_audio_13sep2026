import 'package:flutter_test/flutter_test.dart';

/// Usage: I see a friendly passage error
Future<void> iSeeAFriendlyPassageError(WidgetTester tester) async {
  expect(find.textContaining("Couldn't open that link"), findsWidgets);
  expect(find.textContaining('not a Bible passage'), findsWidgets);
  expect(find.textContaining('NotABook 99:1'), findsWidgets);
  expect(find.textContaining('Love is patient'), findsNothing);
}
