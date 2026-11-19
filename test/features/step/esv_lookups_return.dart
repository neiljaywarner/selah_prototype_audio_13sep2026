import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: ESV lookups return {'Placeholder line only.'}
Future<void> esvLookupsReturn(WidgetTester tester, String line) async {
  SharePassageWorld.esvFallbackText = line;
}
