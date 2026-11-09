import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: ESV lookups continue
Future<void> esvLookupsContinue(WidgetTester tester) async {
  SharePassageWorld.releaseEsvLookups();
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
