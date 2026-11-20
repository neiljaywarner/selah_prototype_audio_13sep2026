import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the share message contains {'(BSB)'}
Future<void> theShareMessageContains(WidgetTester tester, String text) async {
  expect(latestSharePayload().message, contains(text));
}
