import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: I have {'1 Cor 13:4-7'} in My Passages
Future<void> iHaveInMyPassages(WidgetTester tester, String reference) async {
  SharePassageWorld.reset();
  SharePassageWorld.savedPassages = [reference];
  await pumpSharePassageApp(tester);
}
