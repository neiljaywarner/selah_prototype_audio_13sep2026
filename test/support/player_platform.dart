import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs the platform channels the chapter player touches in widget tests:
/// path_provider, text-to-speech, and just_audio. [ttsCalls] records every
/// TTS method so a test can assert that nothing was spoken.
void installSelahPlayerPlatform({List<MethodCall>? ttsCalls}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => '/tmp',
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('flutter_tts'),
    (call) async {
      ttsCalls?.add(call);
      return 1;
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.ryanheise.just_audio.methods'),
    (call) async {
      if (call.method == 'init') {
        final id = (call.arguments as Map?)?['id'] as String? ?? 'test-player';
        messenger.setMockMethodCallHandler(
          MethodChannel('com.ryanheise.just_audio.methods.$id'),
          (playerCall) async {
            if (playerCall.method == 'load') {
              const codec = StandardMethodCodec();
              final event = <String, dynamic>{
                'processingState': 3,
                'updateTime': DateTime.now().millisecondsSinceEpoch,
                'updatePosition': 0,
                'bufferedPosition': 0,
                'duration': 10000000,
                'icyMetadata': null,
                'currentIndex': 0,
                'androidAudioSessionId': null,
              };
              messenger.handlePlatformMessage(
                'com.ryanheise.just_audio.events.$id',
                codec.encodeSuccessEnvelope(event),
                (_) {},
              );
              return {'duration': 10000000};
            }
            return <String, dynamic>{};
          },
        );
        return {'id': id};
      }
      if (call.method == 'load') return {'duration': 10000000};
      return <String, dynamic>{};
    },
  );
}

bool ttsSpoke(List<MethodCall> calls) => calls.any((call) => call.method == 'speak');
