import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the share payload contains the verse {'Love is patient, love is kind'}
Future<void> theSharePayloadContainsTheVerse(
  WidgetTester tester,
  String verse,
) async {
  final payload = latestSharePayload();
  expect(payload.includesVerseText, isTrue);
  expect(payload.message, contains(verse));
  expect(payload.url, isNot(contains(verse)));
}
