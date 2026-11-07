import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the share payload contains {'1 Cor 13:4-7'}
Future<void> theSharePayloadContains(WidgetTester tester, String reference) async {
  final payload = latestSharePayload();
  expect(payload.reference, reference);
  expect(payload.message, contains(reference));
  expect(payload.message, contains(payload.url));
}
