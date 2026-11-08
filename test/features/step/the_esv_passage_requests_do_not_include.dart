import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the ESV passage requests do not include {'John 3:16'}
Future<void> theEsvPassageRequestsDoNotInclude(WidgetTester tester, String query) async {
  expect(SharePassageWorld.esvQueries, isNot(contains(query)));
}
