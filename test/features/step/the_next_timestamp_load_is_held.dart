import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';

/// Usage: the next timestamp load is held
Future<void> theNextTimestampLoadIsHeld(WidgetTester tester) async {
  TimestampLoaderService.debugHoldNextLoad();
}
