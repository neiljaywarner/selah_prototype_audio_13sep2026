import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: public domain lookups continue
Future<void> publicDomainLookupsContinue(WidgetTester tester) async {
  SharePassageWorld.releasePublicDomainLookups();
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
