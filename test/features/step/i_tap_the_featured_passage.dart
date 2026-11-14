import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the featured passage {'1 Cor 13:4'}
Future<void> iTapTheFeaturedPassage(WidgetTester tester, String label) async {
  final chip = find.textContaining(label);
  expect(chip, findsWidgets);
  await tester.ensureVisible(chip.first);
  await tester.tap(chip.first);
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.textContaining('Love is patient').evaluate().isNotEmpty) break;
  }
}
