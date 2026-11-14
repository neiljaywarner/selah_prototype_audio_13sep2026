import 'package:flutter_test/flutter_test.dart';

/// Usage: I see verse timing marked unaligned
Future<void> iSeeVerseTimingMarkedUnaligned(WidgetTester tester) async {
  expect(find.textContaining('Verse timing unaligned'), findsWidgets);
}
