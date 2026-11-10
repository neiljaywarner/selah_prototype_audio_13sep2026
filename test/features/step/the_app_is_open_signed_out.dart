import 'package:flutter_test/flutter_test.dart';

import 'share_passage_harness.dart';

/// Usage: the app is open signed out
Future<void> theAppIsOpenSignedOut(WidgetTester tester) async {
  SharePassageWorld.reset();
  SharePassageWorld.readPlatformLink = true;
  tester.platformDispatcher.defaultRouteNameTestValue = '/';
  addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
  await pumpSharePassageApp(tester);
}
