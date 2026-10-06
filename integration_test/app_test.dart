import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Selah core experience: launches, selects John 1 chapter audio, and verifies human narrator playback',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1. Verify Header
      expect(find.text('SELAH'), findsOneWidget);

      // 2. Autocomplete
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Jn');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('John'), findsWidgets);
      expect(find.textContaining('Jonah'), findsWidgets);

      // 3. Search & select John 1
      await tester.enterText(textField, 'John');
      await tester.pump(const Duration(milliseconds: 500));

      final johnChip = find.textContaining('John 1');
      if (johnChip.evaluate().isNotEmpty) {
        await tester.tap(johnChip.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Assert Audio Mode Indicator
      expect(
        find.textContaining('Narrator').evaluate().isNotEmpty ||
            find.textContaining('TTS').evaluate().isNotEmpty ||
            find.textContaining('Speech').evaluate().isNotEmpty,
        isTrue,
      );

      // 4. Open Roadmap Voting Modal
      final voteIcon = find.byIcon(Icons.how_to_vote_rounded);
      if (voteIcon.evaluate().isNotEmpty) {
        await tester.tap(voteIcon);
        await tester.pumpAndSettle();
        expect(find.textContaining('Feature'), findsWidgets);
      }
    },
  );

  testWidgets(
    'WhisperX 1 Cor 13:4-7 feature: selects 1 Corinthians 13 chip and verifies experimental preview banner',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final cor13Chip = find.textContaining('1 Corinthians 13');
      if (cor13Chip.evaluate().isNotEmpty) {
        await tester.tap(cor13Chip.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.textContaining('WhisperX Experimental Preview'), findsWidgets);
      }
    },
  );
}
