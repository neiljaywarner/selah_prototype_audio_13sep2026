import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Selah core experience', () {
    testWidgets('App launches and shows title', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('SELAH'), findsOneWidget);
    });

    testWidgets('Chapter picker autocomplete works', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Jn');
      await tester.pump(const Duration(milliseconds: 500));

      // Both John and Jonah chips should appear
      expect(find.textContaining('John'), findsWidgets);
      expect(find.textContaining('Jonah'), findsWidgets);
    });

    testWidgets('Tapping John 1 chip navigates to chapter player', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'John');
      await tester.pump(const Duration(milliseconds: 500));

      // Tap the first John chip
      final johnChip = find.textContaining('John 1');
      if (johnChip.evaluate().isNotEmpty) {
        await tester.tap(johnChip.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify we have audio mode indicator (Human Narrator or TTS)
      expect(
        find.textContaining('Narrator').evaluate().isNotEmpty ||
        find.textContaining('TTS').evaluate().isNotEmpty ||
        find.textContaining('Speech').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Voting modal opens', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final voteIcon = find.byIcon(Icons.how_to_vote_rounded);
      expect(voteIcon, findsOneWidget);
      await tester.tap(voteIcon);
      await tester.pumpAndSettle();
      expect(find.textContaining('Feature'), findsWidgets);
    });
  });
}
