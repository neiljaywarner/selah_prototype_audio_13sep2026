import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the next ESV lookup is held
Future<void> theNextEsvLookupIsHeld(WidgetTester tester) async {
  SharePassageWorld.holdTheNextEsvLookup();
}
