import 'package:flutter_test/flutter_test.dart';

/// Usage: I decline read aloud
Future<void> iDeclineReadAloud(WidgetTester tester) async {
  await tester.tap(find.text('Not now'));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('Read this passage aloud?').evaluate().isEmpty) break;
  }
}
