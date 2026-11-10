import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/audio/bundled_audio_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
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

  group('Listening decisions without an ESV key', () {
    test('the player opens on the narrator and does not speak', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(chapterPlayerProvider);

      expect(EsvApiClient().isConfigured, isFalse);
      expect(container.read(esvPassagePolicyProvider).useEsvForPassages, isFalse);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.isPlaying, isFalse);
      expect(state.currentChapter.displayTitle, '1 Cor 13:4–7');
      expect(ttsSpoke(ttsCalls), isFalse);
    });

    test('a missing ESV key refuses the lookup and does not start speech', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chapterPlayerProvider.notifier);

      final played = await notifier.tryPlayEsvPassage('John 11:35');

      expect(played, isFalse);
      expect(container.read(chapterPlayerProvider).isPlaying, isFalse);
      expect(container.read(chapterPlayerProvider).audioMode, AudioMode.narrator);
      expect(ttsSpoke(ttsCalls), isFalse);
    });

    test('bundled audio stays offline and silent until the listener presses play', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chapterPlayerProvider.notifier);

      expect(BundledAudioService.hasBundledAudio('BSB', '1CO', 13), isTrue);
      expect(BundledAudioService.getBundledAudioPath('NIV', '1CO', 13), isNull);

      await notifier.routeAndPlayChapter(
        bookCode: '1CO',
        chapterNumber: 13,
        bookName: '1 Corinthians',
        autoplay: false,
      );

      final state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.isOffline, isTrue);
      expect(state.isPlaying, isFalse);
      expect(state.currentChapter.audioStreamUrl, 'assets/audio/BSB/1CO_13.mp3');
      expect(state.currentChapter.textContent, contains('Love is patient'));
      expect(ttsSpoke(ttsCalls), isFalse);
    });

    test('a chapter with no bundled file and no API key prepares TTS but does not speak', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chapterPlayerProvider.notifier);

      expect(BundledAudioService.hasBundledAudio('BSB', 'LEV', 1), isFalse);

      await notifier.routeAndPlayChapter(
        bookCode: 'LEV',
        chapterNumber: 1,
        bookName: 'Leviticus',
        autoplay: false,
      );

      final state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.tts);
      expect(state.isPlaying, isFalse);
      expect(state.infoNotice, contains('contemplative voice'));
      expect(state.currentChapter.bookCode, 'LEV');
      expect(ttsSpoke(ttsCalls), isFalse);
    });

    test('WEB Old Testament has no human narrator and does not speak on its own', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chapterPlayerProvider.notifier);

      notifier.setTranslation('WEB');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      ttsCalls.clear();

      await notifier.routeAndPlayChapter(
        bookCode: 'GEN',
        chapterNumber: 1,
        bookName: 'Genesis',
        autoplay: false,
      );

      final state = container.read(chapterPlayerProvider);
      expect(state.activeTranslation, 'WEB');
      expect(state.audioMode, AudioMode.tts);
      expect(state.isPlaying, isFalse);
      expect(state.infoNotice, contains('no OT narrator'));
      expect(ttsSpoke(ttsCalls), isFalse);
    });

    test('pressing play on bundled audio starts the narrator and still does not speak', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chapterPlayerProvider.notifier);

      await notifier.routeAndPlayChapter(
        bookCode: 'PSA',
        chapterNumber: 23,
        bookName: 'Psalms',
        autoplay: false,
      );
      expect(container.read(chapterPlayerProvider).isPlaying, isFalse);

      await notifier.play();

      final state = container.read(chapterPlayerProvider);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.isPlaying, isTrue);
      expect(ttsSpoke(ttsCalls), isFalse);
    });

    test('sleep timer and karaoke are listener choices, not playback', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chapterPlayerProvider.notifier);

      notifier.toggleKaraoke(false);
      expect(container.read(chapterPlayerProvider).karaokeEnabled, isFalse);

      notifier.setSleepTimer(25);
      expect(container.read(chapterPlayerProvider).sleepTimerMinutes, 25);
      expect(container.read(chapterPlayerProvider).isPlaying, isFalse);

      notifier.setSleepTimer(null);
      expect(container.read(chapterPlayerProvider).sleepTimerMinutes, isNull);
      expect(ttsSpoke(ttsCalls), isFalse);
    });
  });
}
