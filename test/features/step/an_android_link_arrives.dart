import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: an Android link arrives {'https://selahword.web.app/?ref=...'}
Future<void> anAndroidLinkArrives(WidgetTester tester, String url) async {
  const channel = SystemChannels.navigation;
  final completer = Completer<ByteData?>();
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    channel.name,
    channel.codec.encodeMethodCall(
      MethodCall('pushRouteInformation', <String, dynamic>{'location': url}),
    ),
    completer.complete,
  );
  await completer.future;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
