import 'package:flutter_test/flutter_test.dart';

/// Usage: I do not see verse timing marked unaligned
Future<void> iDoNotSeeVerseTimingMarkedUnaligned(WidgetTester tester) async {
  expect(find.textContaining('Verse timing unaligned'), findsNothing);
}
