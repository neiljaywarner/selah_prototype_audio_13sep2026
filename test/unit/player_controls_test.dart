import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';

import '../support/player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ttsCalls = <MethodCall>[];

  setUp(() {
    ttsCalls.clear();
    installSelahPlayerPlatform(ttsCalls: ttsCalls);
    SharedPreferences.setMockInitialValues({});
  });

  test('speed is clamped, the pause gap is a listener choice, and seek does not speak', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(chapterPlayerProvider.notifier);

    await notifier.setPlaybackSpeed(3);
    expect(container.read(chapterPlayerProvider).playbackSpeed, 2.0);
    await notifier.setPlaybackSpeed(0.1);
    expect(container.read(chapterPlayerProvider).playbackSpeed, 0.5);

    notifier.setPauseGap(8);
    expect(container.read(chapterPlayerProvider).pauseGapSeconds, 8);

    notifier.seek(const Duration(seconds: 4));
    expect(container.read(chapterPlayerProvider).isPlaying, isFalse);
    expect(ttsSpoke(ttsCalls), isFalse);
  });

  test('play then pause on bundled audio never calls text-to-speech', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(chapterPlayerProvider.notifier);

    await notifier.routeAndPlayChapter(
      bookCode: 'MAT',
      chapterNumber: 11,
      bookName: 'Matthew',
      autoplay: false,
    );
    expect(container.read(chapterPlayerProvider).isPlaying, isFalse);
    expect(container.read(chapterPlayerProvider).audioMode, AudioMode.narrator);

    notifier.togglePlayPause();
    await testerDelay();
    expect(container.read(chapterPlayerProvider).isPlaying, isTrue);
    expect(ttsSpoke(ttsCalls), isFalse);

    await notifier.pause();
    expect(container.read(chapterPlayerProvider).isPlaying, isFalse);
    expect(ttsSpoke(ttsCalls), isFalse);
  });

  test('choosing the current translation again does not restart audio', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(chapterPlayerProvider.notifier);
    final before = container.read(chapterPlayerProvider).currentChapter.reference;

    notifier.setTranslation('BSB');

    expect(container.read(chapterPlayerProvider).activeTranslation, 'BSB');
    expect(container.read(chapterPlayerProvider).currentChapter.reference, before);
    expect(container.read(chapterPlayerProvider).isPlaying, isFalse);
    expect(ttsSpoke(ttsCalls), isFalse);
  });
}

Future<void> testerDelay() => Future<void>.delayed(const Duration(milliseconds: 50));
