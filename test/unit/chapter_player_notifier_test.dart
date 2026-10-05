import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChapterPlayerNotifier Unit Tests', () {
    test('Initial state has featured chapter and narrator mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(chapterPlayerProvider);
      expect(state.currentChapter, isNotNull);
      expect(state.audioMode, equals(AudioMode.narrator));
    });

    test('Translation change updates active translation state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chapterPlayerProvider.notifier);
      notifier.setTranslation('BSB');

      final state = container.read(chapterPlayerProvider);
      expect(state.activeTranslation, equals('BSB'));
    });
  });
}
