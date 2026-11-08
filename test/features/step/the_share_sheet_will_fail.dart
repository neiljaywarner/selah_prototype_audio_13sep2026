import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the share sheet will fail
Future<void> theShareSheetWillFail(WidgetTester tester) async {
  SharePassageWorld.shareShouldFail = true;
}
