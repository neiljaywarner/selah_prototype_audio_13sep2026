import 'package:flutter_test/flutter_test.dart';

/// Usage: I confirm read aloud
Future<void> iConfirmReadAloud(WidgetTester tester) async {
  await tester.tap(find.text('Read aloud'));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
