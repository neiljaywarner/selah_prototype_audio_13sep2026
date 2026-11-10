import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the app opens from the Android link {'https://selahword.web.app/?ref=...'}
Future<void> theAppOpensFromTheAndroidLink(WidgetTester tester, String url) async {
  SharePassageWorld.reset();
  SharePassageWorld.readPlatformLink = true;
  tester.platformDispatcher.defaultRouteNameTestValue = url;
  addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
  await pumpSharePassageApp(tester);
}
