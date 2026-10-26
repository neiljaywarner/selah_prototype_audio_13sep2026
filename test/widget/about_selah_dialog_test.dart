import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/about_selah_dialog.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

void main() {
  group('AboutSelahDialog Widget Tests (#45)', () {
    testWidgets('Tapping info button on AppBar opens AboutSelahDialog with credits & release notes', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChapterPlayerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find About info button on AppBar
      final infoButton = find.byTooltip('About Selah');
      expect(infoButton, findsOneWidget);

      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      // Verify About Dialog content
      expect(find.byType(AboutSelahDialog), findsOneWidget);
      expect(find.text('SELAH'), findsWidgets);
      expect(find.textContaining('v0.4.1'), findsWidgets);
      expect(
        find.textContaining('Crafted by Neil Jay Warner, and friends and brothers and sisters in Christ'),
        findsOneWidget,
      );
      expect(find.text('Scripture Copyrights & Attributions'), findsOneWidget);
      expect(find.text('Release Notes (v0.4.1)'), findsOneWidget);
      expect(find.text('View Scripture & Audio Attributions'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutSelahDialog), findsNothing);
    });

    testWidgets('Tapping View Scripture & Audio Attributions opens LicensingAttributionSheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChapterPlayerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final infoButton = find.byTooltip('About Selah');
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      final licensingButton = find.text('View Scripture & Audio Attributions');
      expect(licensingButton, findsOneWidget);
      await tester.ensureVisible(licensingButton);
      await tester.pumpAndSettle();
      await tester.tap(licensingButton);
      await tester.pumpAndSettle();

      expect(find.text('Scripture & Audio Licensing'), findsOneWidget);
      expect(find.text('Text & Scripture Rights'), findsOneWidget);
      expect(find.text('Narrator & Audio Production'), findsOneWidget);

      // Close attribution sheet
      await tester.tap(find.byKey(const Key('close_attribution_details_button')));
      await tester.pumpAndSettle();

      expect(find.text('Scripture & Audio Licensing'), findsNothing);
    });
  });
}
