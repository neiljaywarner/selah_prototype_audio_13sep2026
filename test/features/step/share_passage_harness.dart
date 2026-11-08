import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/remote_config/remote_config_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/passage_share_launcher.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Last payload the share button handed to the launcher.
/// The native share sheet itself does not run in widget tests.
class RecordingPassageShareLauncher implements PassageShareLauncher {
  PassageSharePayload? last;

  @override
  Future<void> share(PassageSharePayload payload) async {
    last = payload;
  }
}

class SharePassageWorld {
  static String? initialShareUrl;
  static List<String> savedPassages = const [];
  static final launcher = RecordingPassageShareLauncher();

  static void reset() {
    initialShareUrl = null;
    savedPassages = const [];
    launcher.last = null;
  }
}

class _QuietRemoteConfig extends RemoteConfigNotifier {
  @override
  SelahRemoteConfig build() => const SelahRemoteConfig();
}

void installPlaybackChannelMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('com.ryanheise.just_audio.methods'), (call) async {
    if (call.method == 'init') {
      final id = (call.arguments as Map?)?['id'] as String? ?? 'test-player';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel('com.ryanheise.just_audio.methods.$id'),
        (playerCall) async {
          if (playerCall.method == 'load') return {'duration': 10000000};
          return <String, dynamic>{};
        },
      );
      return {'id': id};
    }
    return <String, dynamic>{};
  });
}

Future<void> pumpSharePassageApp(WidgetTester tester) async {
  installPlaybackChannelMocks();
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({
    UserPreferences.savedChaptersKey: List<String>.from(SharePassageWorld.savedPassages),
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        passageShareLauncherProvider.overrideWithValue(SharePassageWorld.launcher),
        remoteConfigProvider.overrideWith(_QuietRemoteConfig.new),
      ],
      child: MaterialApp(
        home: ChapterPlayerScreen(
          initialShareUrl: SharePassageWorld.initialShareUrl,
          readPlatformLink: false,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

PassageSharePayload latestSharePayload() {
  final payload = SharePassageWorld.launcher.last;
  expect(payload, isNotNull, reason: 'No passage was shared');
  return payload!;
}
