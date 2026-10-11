import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Selah core experience: launches, verifies header, search autocomplete, and voting modal',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1. Verify Header
      expect(find.text('SELAH'), findsOneWidget);

      // 2. Autocomplete suggestions
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Jn');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('John'), findsWidgets);

      // Clear search field
      await tester.enterText(textField, '');
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Open Roadmap Voting Modal
      final voteIcon = find.byIcon(Icons.how_to_vote_rounded);
      if (voteIcon.evaluate().isNotEmpty) {
        await tester.tap(voteIcon);
        await tester.pumpAndSettle();
        expect(find.textContaining('Feature'), findsWidgets);

        // Close modal
        final closeFinder = find.byIcon(Icons.close_rounded);
        if (closeFinder.evaluate().isNotEmpty) {
          await tester.tap(closeFinder);
          await tester.pumpAndSettle();
        } else {
          await tester.tapAt(const Offset(20, 20));
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets(
    'WhisperX curated passages: displays chips for 1 Cor 13, Matt 11, Rom 8, and Psalm 23',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify all 4 curated chips are present in the presets row
      expect(find.text('1 Cor 13:4–7'), findsWidgets);
      expect(find.text('Matt 11:28–30'), findsOneWidget);
      expect(find.text('Rom 8:31–39'), findsOneWidget);
      expect(find.text('Psalm 23'), findsOneWidget);

      // Verify default excerpt starts at Verse 4
      expect(find.textContaining('Love is patient, love is kind'), findsOneWidget);
    },
  );

  testWidgets(
    'Uncurated verse range guardrail: displays Feature Coming Soon snackbar on custom ranges',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'col 1:17-20');
      await tester.pumpAndSettle();

      final playButton = find.widgetWithText(ElevatedButton, 'Play');
      expect(playButton, findsOneWidget);
      await tester.tap(playButton);
      await tester.pump();

      expect(
        find.textContaining('Feature coming soon! Custom verse range "col 1:17-20" will be supported in v0.3.0.'),
        findsOneWidget,
      );
    },
  );
}
