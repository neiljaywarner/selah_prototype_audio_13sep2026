import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';

/// BDD Step Implementations mapped directly to test/features/curated_passages_whisperx.feature
void main() {
  group('BDD Feature: Curated WhisperX Passage Audio Excerpts and Guardrails', () {
    testWidgets('Scenario: Display curated passage chips in the horizontal presets bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Given the Selah meditation app is running
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle();

      // Then the horizontal presets bar displays all 4 curated chips
      expect(find.text('1 Cor 13:4–7'), findsWidgets);
      expect(find.text('Matt 11:28–30'), findsOneWidget);
      expect(find.text('Rom 8:31–39'), findsOneWidget);
      expect(find.text('Psalm 23'), findsOneWidget);
    });

    testWidgets('Scenario: Selecting Matthew 11:28-30 excerpt loads text and excerpt title', (tester) async {
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

      final mattPreset = kFeaturedChapters.firstWhere(
        (c) => c.bookCode == 'MAT' && c.chapterNumber == 11,
      );

      // When Matthew 11:28–30 excerpt is loaded
      container.read(chapterPlayerProvider.notifier).state =
          container.read(chapterPlayerProvider).copyWith(
                currentChapter: mattPreset,
              );
      await tester.pumpAndSettle();

      // Then the player title displays "Matt 11:28–30"
      expect(find.text('Matt 11:28–30'), findsWidgets);
      // And the text preview contains "Come to Me, all you who are weary"
      expect(
        find.textContaining('Come to Me, all you who are weary and burdened'),
        findsOneWidget,
      );
    });

    testWidgets('Scenario: Selecting Romans 8:31-39 excerpt loads text and excerpt title', (tester) async {
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

      final romPreset = kFeaturedChapters.firstWhere(
        (c) => c.bookCode == 'ROM' && c.chapterNumber == 8,
      );

      // When Romans 8:31–39 excerpt is loaded
      container.read(chapterPlayerProvider.notifier).state =
          container.read(chapterPlayerProvider).copyWith(
                currentChapter: romPreset,
              );
      await tester.pumpAndSettle();

      // Then the player title displays "Rom 8:31–39"
      expect(find.text('Rom 8:31–39'), findsWidgets);
      // And the text preview contains "If God is for us, who can be against us?"
      expect(
        find.textContaining('If God is for us, who can be against us?'),
        findsOneWidget,
      );
    });

    testWidgets('Scenario: Selecting Psalm 23 excerpt loads text and excerpt title', (tester) async {
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

      final psaPreset = kFeaturedChapters.firstWhere(
        (c) => c.bookCode == 'PSA' && c.chapterNumber == 23,
      );

      // When Psalm 23 excerpt is loaded
      container.read(chapterPlayerProvider.notifier).state =
          container.read(chapterPlayerProvider).copyWith(
                currentChapter: psaPreset,
              );
      await tester.pumpAndSettle();

      // Then the player title displays "Psalm 23"
      expect(find.text('Psalm 23'), findsWidgets);
      // And the text preview contains "The LORD is my shepherd"
      expect(
        find.textContaining('The LORD is my shepherd; I shall not want'),
        findsOneWidget,
      );
    });

    testWidgets('Scenario: Custom uncurated verse range search displays Coming Soon snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle();

      // When the user enters "col 1:17-20" in the reference search box
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'col 1:17-20');
      await tester.pumpAndSettle();

      // And taps the Play button
      final playButton = find.widgetWithText(ElevatedButton, 'Play');
      expect(playButton, findsOneWidget);
      await tester.tap(playButton);
      await tester.pump();

      // Then a floating SnackBar appears with message
      expect(
        find.textContaining('Feature coming soon! Custom verse range "col 1:17-20" will be supported in v0.3.0.'),
        findsOneWidget,
      );
    });
  });
}
