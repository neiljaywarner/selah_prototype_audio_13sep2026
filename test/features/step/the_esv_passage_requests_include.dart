import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the ESV passage requests include {'John 16:32'}
Future<void> theEsvPassageRequestsInclude(WidgetTester tester, String query) async {
  expect(SharePassageWorld.esvQueries, contains(query));
}
