import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: I open the share link {'https://...'} while signed out
Future<void> iOpenTheShareLinkWhileSignedOut(WidgetTester tester, String url) async {
  SharePassageWorld.reset();
  SharePassageWorld.initialShareUrl = url;
  await pumpSharePassageApp(tester);
}
