import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/cache/public_domain_passage_text.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
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
    if (SharePassageWorld.shareShouldFail) {
      SharePassageWorld.shareShouldFail = false;
      throw StateError('share sheet failed');
    }
  }
}

class SharePassageWorld {
  static String? initialShareUrl;
  static List<String> savedPassages = const [];
  static final launcher = RecordingPassageShareLauncher();

  /// BSB, WEB, or ESV. Null leaves the app on its default (BSB when no ESV key).
  static String? forcedTranslation;
  static final List<String> esvQueries = [];
  static bool shareShouldFail = false;

  /// When set, scripted ESV responses wait until [releaseEsvLookups].
  /// [holdEveryEsvLookup] holds every response. [esvHoldsRemaining] holds
  /// only the next few responses, so a later search can finish first.
  static Completer<void>? esvGate;
  static bool holdEveryEsvLookup = false;
  static int esvHoldsRemaining = 0;
  static Completer<void>? publicDomainGate;
  static Completer<void>? playbackStopGate;

  static void reset() {
    if (esvGate != null && !esvGate!.isCompleted) {
      esvGate!.complete();
    }
    if (publicDomainGate != null && !publicDomainGate!.isCompleted) {
      publicDomainGate!.complete();
    }
    if (playbackStopGate != null && !playbackStopGate!.isCompleted) {
      playbackStopGate!.complete();
    }
    initialShareUrl = null;
    savedPassages = const [];
    launcher.last = null;
    forcedTranslation = null;
    esvQueries.clear();
    shareShouldFail = false;
    esvGate = null;
    holdEveryEsvLookup = false;
    esvHoldsRemaining = 0;
    publicDomainGate = null;
    playbackStopGate = null;
  }

  static void holdEsvLookups() {
    esvGate = Completer<void>();
    holdEveryEsvLookup = true;
    esvHoldsRemaining = 0;
  }

  static void holdTheNextEsvLookup() {
    esvGate = Completer<void>();
    holdEveryEsvLookup = false;
    esvHoldsRemaining = 1;
  }

  static void releaseEsvLookups() {
    final gate = esvGate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  static void holdPublicDomainLookups() {
    publicDomainGate = Completer<void>();
  }

  static void releasePublicDomainLookups() {
    final gate = publicDomainGate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  static void holdPlaybackStops() {
    playbackStopGate = Completer<void>();
  }

  static void releasePlaybackStops() {
    final gate = playbackStopGate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }
}

class _QuietRemoteConfig extends RemoteConfigNotifier {
  @override
  SelahRemoteConfig build() => const SelahRemoteConfig();
}

void installPlaybackChannelMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
    if (call.method == 'stop') {
      final gate = SharePassageWorld.playbackStopGate;
      if (gate != null && !gate.isCompleted) await gate.future;
    }
    return 1;
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('com.ryanheise.just_audio.methods'), (call) async {
    if (call.method == 'init') {
      final id = (call.arguments as Map?)?['id'] as String? ?? 'test-player';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel('com.ryanheise.just_audio.methods.$id'),
        (playerCall) async {
          if (playerCall.method == 'load') {
            final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
            const codec = StandardMethodCodec();
            messenger.handlePlatformMessage(
              'com.ryanheise.just_audio.events.$id',
              codec.encodeSuccessEnvelope(<String, dynamic>{
                'processingState': 3,
                'updateTime': DateTime.now().millisecondsSinceEpoch,
                'updatePosition': 0,
                'bufferedPosition': 0,
                'duration': 12000000,
                'icyMetadata': null,
                'currentIndex': 0,
                'androidAudioSessionId': null,
              }),
              (_) {},
            );
            return {'duration': 12000000};
          }
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

  final initialPrefs = <String, Object>{
    UserPreferences.savedChaptersKey: List<String>.from(SharePassageWorld.savedPassages),
  };
  final forced = SharePassageWorld.forcedTranslation;
  if (forced == 'WEB' || forced == 'BSB') {
    initialPrefs[UserPreferences.lastTranslationKey] = forced!;
  }
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();

  final overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
    passageShareLauncherProvider.overrideWithValue(SharePassageWorld.launcher),
    remoteConfigProvider.overrideWith(_QuietRemoteConfig.new),
  ];
  overrides.add(
    publicDomainPassageTextProvider.overrideWithValue(
      PublicDomainPassageText(dio: Dio()..httpClientAdapter = _ScriptedPublicDomainAdapter()),
    ),
  );
  if (forced == 'ESV') {
    overrides.add(
      esvApiClientProvider.overrideWithValue(
        EsvApiClient(
          apiKey: 'test-esv-key',
          dio: Dio()..httpClientAdapter = _ScriptedEsvAdapter(),
        ),
      ),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
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

/// Stand-in Crossway responses. No live ESV key is required, and no copyrighted
/// ESV verse body is stored here.
/// Real public-domain John 16:32-33 wording, captured from Helloao.
/// Widget tests cannot open a socket, so this adapter serves that text.
class _ScriptedPublicDomainAdapter implements HttpClientAdapter {
  static const _bsb32 =
      '“Look, an hour is coming and has already come when you will be scattered, each to his own home, and you will leave Me all alone. Yet I am not alone, because the Father is with Me.';
  static const _bsb33 =
      'I have told you these things so that in Me you may have peace. In the world you will have tribulation. But take courage; I have overcome the world!”';
  static const _web32 =
      'Behold, the time is coming, yes, and has now come, that you will be scattered, everyone to his own place, and you will leave me alone. Yet I am not alone, because the Father is with me.';
  static const _web33 =
      'I have told you these things, that in me you may have peace. In the world you have trouble; but cheer up! I have overcome the world.”';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final gate = SharePassageWorld.publicDomainGate;
    if (gate != null) await gate.future;
    if (!options.uri.path.contains('/JHN/16')) {
      return ResponseBody.fromString(
        '{}',
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    final web = options.uri.path.contains('eng_web');
    final payload = {
      'chapter': {
        'content': [
          {'type': 'verse', 'number': 32, 'content': [web ? _web32 : _bsb32]},
          {'type': 'verse', 'number': 33, 'content': [web ? _web33 : _bsb33]},
        ],
      },
    };
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ScriptedEsvAdapter implements HttpClientAdapter {
  static const verses = <String, String>{
    'John 16:32': 'Fixture text for John sixteen verse thirty-two only.',
    'John 16:33': 'Fixture text for John sixteen verse thirty-three only.',
    'John 3:16': 'Fixture text for John three verse sixteen only.',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = '${options.queryParameters['q'] ?? ''}';
    if (query.isNotEmpty) SharePassageWorld.esvQueries.add(query);
    final gate = SharePassageWorld.esvGate;
    if (gate != null && !gate.isCompleted) {
      if (SharePassageWorld.holdEveryEsvLookup) {
        await gate.future;
      } else if (SharePassageWorld.esvHoldsRemaining > 0) {
        SharePassageWorld.esvHoldsRemaining--;
        await gate.future;
      }
    }
    final payload = <String, dynamic>{
      'canonical': query,
      'passages': <String>['${verses[query] ?? ''}\n\n'],
    };
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
