import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the share payload does not contain the verse {'Love is patient, love is kind'}
Future<void> theSharePayloadDoesNotContainTheVerse(
  WidgetTester tester,
  String verse,
) async {
  final payload = latestSharePayload();
  final blob = '${payload.message}\n${payload.url}\n${payload.attribution ?? ''}';
  expect(blob.contains(verse), isFalse);
  expect(blob.toLowerCase().contains('it does not envy'), isFalse);
}
