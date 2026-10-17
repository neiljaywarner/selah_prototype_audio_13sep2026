import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Passage Acoustic Fallback (TimestampLoaderService)', () {
    test('estimateVerseTimestamps divides duration proportionally by verse word count', () {
      const chapterText = '''
1 In the beginning God created the heavens and the earth.
2 The earth was without form and void, and darkness was over the face of the deep. And the Spirit of God was hovering over the face of the waters.
3 And God said, "Let there be light," and there was light.
''';

      const totalDuration = Duration(seconds: 30);
      final timestamps = TimestampLoaderService.estimateVerseTimestamps(
        textContent: chapterText,
        totalDuration: totalDuration,
      );

      expect(timestamps.length, equals(3));
      expect(timestamps[0].verse, equals(1));
      expect(timestamps[0].startMs, equals(0));
      expect(timestamps[0].endMs, greaterThan(0));

      expect(timestamps[1].verse, equals(2));
      expect(timestamps[1].startMs, greaterThan(timestamps[0].startMs));

      expect(timestamps[2].verse, equals(3));
      expect(timestamps[2].endMs, equals(30000));
    });

    test('estimateVerseTimestamps returns empty list for empty text or zero duration', () {
      expect(
        TimestampLoaderService.estimateVerseTimestamps(
          textContent: '',
          totalDuration: const Duration(seconds: 30),
        ),
        isEmpty,
      );

      expect(
        TimestampLoaderService.estimateVerseTimestamps(
          textContent: '1 In the beginning God created the heavens.',
          totalDuration: Duration.zero,
        ),
        isEmpty,
      );
    });
  });

  group('ChapterPlayerState Sleep Timer & Playback Speed', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ChapterPlayerState defaults to 1.0x speed and inactive sleep timer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(chapterPlayerProvider);
      expect(state.playbackSpeed, equals(1.0));
      expect(state.sleepTimerMinutes, isNull);
      expect(state.isSleepTimerActive, isFalse);
      expect(state.sleepTimerRemaining, equals(Duration.zero));
    });

    test('ChapterPlayerState copyWith updates speed and sleep timer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(chapterPlayerProvider);
      final futureEnd = DateTime.now().add(const Duration(minutes: 30));

      final updated = state.copyWith(
        playbackSpeed: 0.85,
        sleepTimerMinutes: 30,
        sleepTimerEndTime: futureEnd,
      );

      expect(updated.playbackSpeed, equals(0.85));
      expect(updated.sleepTimerMinutes, equals(30));
      expect(updated.isSleepTimerActive, isTrue);
      expect(updated.sleepTimerRemaining.inMinutes, greaterThanOrEqualTo(29));

      final cleared = updated.copyWith(clearSleepTimer: true);
      expect(cleared.sleepTimerMinutes, isNull);
      expect(cleared.isSleepTimerActive, isFalse);
    });
  });

  group('ChapterPlayerNotifier Sleep Timer & Speed Controls', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setPlaybackSpeed clamps and updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chapterPlayerProvider.notifier);
      await notifier.setPlaybackSpeed(0.85);

      expect(container.read(chapterPlayerProvider).playbackSpeed, equals(0.85));

      await notifier.setPlaybackSpeed(1.1);
      expect(container.read(chapterPlayerProvider).playbackSpeed, equals(1.1));
    });

    test('setSleepTimer schedules and cancels tranquil sleep timer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chapterPlayerProvider.notifier);

      // Set 15m timer
      notifier.setSleepTimer(15);
      var state = container.read(chapterPlayerProvider);
      expect(state.sleepTimerMinutes, equals(15));
      expect(state.isSleepTimerActive, isTrue);

      // Cancel timer
      notifier.setSleepTimer(null);
      state = container.read(chapterPlayerProvider);
      expect(state.sleepTimerMinutes, isNull);
      expect(state.isSleepTimerActive, isFalse);
    });
  });
}
