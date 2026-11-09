import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I turn on API.Bible narrator translations
Future<void> iTurnOnApibibleNarratorTranslations(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  );
  await container
      .read(experimentalApiBibleNarratorProvider.notifier)
      .setEnabled(true);
  await tester.pump();
}
