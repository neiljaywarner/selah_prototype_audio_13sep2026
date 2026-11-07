import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the share link contains {'1+Cor+13:4-7'}
Future<void> theShareLinkContains(WidgetTester tester, String token) async {
  final payload = latestSharePayload();
  expect(payload.url, contains(token));
  expect(payload.url, contains('?ref='));
  expect(payload.url, startsWith('https://'));
}
