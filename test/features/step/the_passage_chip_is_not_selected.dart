import 'package:flutter_test/flutter_test.dart';

import 'passage_chip_selection.dart';

/// Usage: the passage chip {'1 Cor 13:4–7'} is not selected
Future<void> thePassageChipIsNotSelected(
  WidgetTester tester,
  String label,
) async {
  await tester.pump(const Duration(milliseconds: 200));
  expect(
    passageChipLooksSelected(tester, label),
    isFalse,
    reason: passageChipSelectionReason(tester, label, expectedSelected: false),
  );
}
