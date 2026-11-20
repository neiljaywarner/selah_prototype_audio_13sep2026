import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the share message does not contain {'Crossway'}
Future<void> theShareMessageDoesNotContain(
  WidgetTester tester,
  String text,
) async {
  expect(latestSharePayload().message, isNot(contains(text)));
}
