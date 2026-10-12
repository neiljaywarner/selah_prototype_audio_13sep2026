import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';

void main() {
  group('1 Corinthians 13:4-7 Verse 4 Widget Tests', () {
    testWidgets('ChapterPlayerScreen displays 1 Corinthians 13 starting at Verse 4', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const SelahApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final corPreset = kFeaturedChapters.firstWhere(
        (c) => c.bookCode == '1CO' && c.chapterNumber == 13,
      );

      container.read(chapterPlayerProvider.notifier).state =
          container.read(chapterPlayerProvider).copyWith(
                currentChapter: corPreset,
              );
      await tester.pumpAndSettle();

      // Verify that the scripture text starts directly at Verse 4 ("Love is patient, love is kind")
      expect(find.textContaining('Love is patient, love is kind', findRichText: true), findsOneWidget);

      // Verify that Verses 1-3 are NOT displayed in the meditation text
      expect(find.textContaining('Though I speak with the tongues', findRichText: true), findsNothing);
      expect(find.textContaining('If I speak with the tongues', findRichText: true), findsNothing);
    });

    testWidgets('Preset chips for curated passages (1 Cor 13:4–7, Matt 11:28–30, Rom 8:31–39, Psalm 23) are present', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: SelahApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Curated demo passage chips should be present in the horizontal list
      expect(find.text('1 Cor 13:4–7'), findsWidgets); // present in preset chip and title header
      expect(find.text('Matt 11:28–30'), findsOneWidget);
      expect(find.text('Rom 8:31–39'), findsOneWidget);
      expect(find.text('Psalm 23'), findsOneWidget);
    });

    testWidgets('Karaoke highlight highlights Verse 4 from character 0 at 39,600ms boundary', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const SelahApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final corPreset = kFeaturedChapters.firstWhere(
        (c) => c.bookCode == '1CO' && c.chapterNumber == 13,
      );

      const v4Text = 'Love is patient, love is kind';
      container.read(chapterPlayerProvider.notifier).state =
          container.read(chapterPlayerProvider).copyWith(
                currentChapter: corPreset,
                position: const Duration(milliseconds: 39600),
                highlightStart: 0,
                highlightEnd: v4Text.length,
              );
      await tester.pump();

      // Find RichText displaying the highlighted text
      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText && widget.text is TextSpan) {
          final span = widget.text as TextSpan;
          if (span.children != null && span.children!.isNotEmpty) {
            return span.children!.any((c) =>
                c is TextSpan &&
                c.text == v4Text &&
                c.style?.backgroundColor == const Color(0xFFFBBF24));
          }
        }
        return false;
      });

      expect(richTextFinder, findsOneWidget, reason: 'Verse 4 should be highlighted with gold background Color(0xFFFBBF24)');
    });

    testWidgets('Searching non-curated verse range (e.g. "col 1:17-20") shows "Sorry, please request this passage with the devs" SnackBar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: SelahApp(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'col 1:17-20');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.textContaining('Sorry, please request this passage with the devs!'), findsOneWidget);
      expect(find.text('Request'), findsOneWidget);
    });
  });
}
