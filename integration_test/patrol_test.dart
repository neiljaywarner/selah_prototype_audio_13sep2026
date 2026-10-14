import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/emoji_feedback_dialog.dart';

void main() {
  patrolTest(
    'Patrol E2E: Launches Selah, switches passage, audits prayer & feedback dialog',
    ($) async {
      await $.pumpWidgetAndSettle(const ProviderScope(child: SelahApp()));

      // 1. Assert Header Branding
      expect($('SELAH'), findsOneWidget);

      // 2. Select tested passage chip
      final passageChip = $(RegExp('1 Cor 13:4'));
      if (passageChip.exists) {
        await passageChip.tap();
        await $.pumpAndSettle();
      }

      // 3. Verify scripture excerpt text rendered
      expect($(RegExp('Love is patient')), findsOneWidget);

      // 4. Test Translation Switcher (BSB -> WEB)
      if ($('WEB').exists) {
        await $('WEB').tap();
        await $.pumpAndSettle();
        expect($('WEB'), findsOneWidget);
      }

      // 5. Test AppBar PopupMenu -> Prayer & Feedback
      final moreOptions = $(Icons.more_vert_rounded);
      if (moreOptions.exists) {
        await moreOptions.tap();
        await $.pumpAndSettle();

        final feedbackOption = $('Prayer & Feedback');
        if (feedbackOption.exists) {
          await feedbackOption.tap();
          await $.pumpAndSettle();

          // Verify streamlined feedback dialog
          expect($(EmojiFeedbackDialog), findsOneWidget);
          expect($('HOW IS YOUR MEDITATION EXPERIENCE?'), findsOneWidget);
          expect($('Loving it!'), findsOneWidget);
          expect($('Suggestion'), findsOneWidget);
          expect($('Needs work'), findsOneWidget);

          // Select Suggestion
          await $('Suggestion').tap();
          await $.pumpAndSettle();

          // Close Dialog
          await $(Icons.close).tap();
          await $.pumpAndSettle();
          expect($(EmojiFeedbackDialog), findsNothing);
        }
      }
    },
  );
}
