import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: I open the share link {'url'} in {'BSB'} while signed out
Future<void> iOpenTheShareLinkInWhileSignedOut(
  WidgetTester tester,
  String url,
  String translation,
) async {
  SharePassageWorld.reset();
  SharePassageWorld.initialShareUrl = url;
  SharePassageWorld.forcedTranslation = translation;
  await pumpSharePassageApp(tester);
}
