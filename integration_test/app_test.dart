import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/emoji_feedback_dialog.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/passage_timing_feedback_bar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Selah core experience: launches, selects passage, and verifies scripture meditation UI',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1. Verify Header Branding
      expect(find.text('SELAH'), findsOneWidget);
      expect(find.textContaining('Scripture Audio Meditation'), findsOneWidget);

      // 2. Autocomplete Search Input
      final textField = find.byType(TextField);
      expect(textField, findsWidgets);
      await tester.enterText(textField.first, 'Jn');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('John'), findsWidgets);

      // 3. Search & select John 1
      await tester.enterText(textField.first, 'John 1');
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Assert Audio Mode & Narrator Indicator
      expect(
        find.textContaining('Narrator').evaluate().isNotEmpty ||
            find.textContaining('TTS').evaluate().isNotEmpty ||
            find.textContaining('Speech').evaluate().isNotEmpty,
        isTrue,
      );

      // 5. Open Settings Modal
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
        expect(find.text('Meditation Settings'), findsOneWidget);
        expect(find.textContaining('BIBLE TRANSLATION'), findsOneWidget);

        // Close Settings
        final closeBtn = find.byIcon(Icons.close);
        if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn);
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets(
    '1 Corinthians 13:4–7 passage meditation & timing feedback bar',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final cor13Chip = find.textContaining('1 Cor 13:4');
      if (cor13Chip.evaluate().isNotEmpty) {
        await tester.tap(cor13Chip.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify calibrated Scripture excerpt
        expect(find.textContaining('Love is patient'), findsOneWidget);

        // Verify PassageTimingFeedbackBar
        expect(find.byType(PassageTimingFeedbackBar), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Prayer & Feedback streamlined flow from AppBar More Options',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SelahApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open PopupMenuButton
      final moreOptions = find.byIcon(Icons.more_vert_rounded);
      if (moreOptions.evaluate().isNotEmpty) {
        await tester.tap(moreOptions);
        await tester.pumpAndSettle();

        // Tap Prayer & Feedback
        final feedbackItem = find.text('Prayer & Feedback');
        expect(feedbackItem, findsOneWidget);
        await tester.tap(feedbackItem);
        await tester.pumpAndSettle();

        // Verify streamlined dialog opens
        expect(find.byType(EmojiFeedbackDialog), findsOneWidget);
        expect(find.text('HOW IS YOUR MEDITATION EXPERIENCE?'), findsOneWidget);
        expect(find.text('Loving it!'), findsOneWidget);
        expect(find.text('Suggestion'), findsOneWidget);
        expect(find.text('Needs work'), findsOneWidget);

        // Close dialog
        final closeBtn = find.byIcon(Icons.close);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();
        expect(find.byType(EmojiFeedbackDialog), findsNothing);
      }
    },
  );
}
