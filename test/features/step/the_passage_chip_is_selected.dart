import 'package:flutter_test/flutter_test.dart';

import 'passage_chip_selection.dart';

/// Usage: the passage chip {'1 Cor 13:4–7'} is selected
Future<void> thePassageChipIsSelected(WidgetTester tester, String label) async {
  await tester.pump(const Duration(milliseconds: 200));
  expect(
    passageChipLooksSelected(tester, label),
    isTrue,
    reason: passageChipSelectionReason(tester, label, expectedSelected: true),
  );
}
