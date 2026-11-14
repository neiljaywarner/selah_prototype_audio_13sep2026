import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

/// Usage: I choose the {'WEB'} translation
Future<void> iChooseTheTranslation(WidgetTester tester, String code) async {
  final label = find.text(code);
  expect(label, findsWidgets);
  await tester.ensureVisible(label.last);
  await tester.tap(label.last);
  await tester.pump();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChapterPlayerScreen)),
  );
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (!container.read(chapterPlayerProvider).isLoading) break;
  }
}
