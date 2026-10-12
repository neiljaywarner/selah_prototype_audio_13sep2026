import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/emoji_feedback_dialog.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/settings_bottom_sheet.dart';

void main() {
  group('EmojiFeedbackDialog Widget Tests (#49)', () {
    testWidgets('Renders all emoji reaction options and stars', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EmojiFeedbackDialog.show(
                  context,
                  currentChapter: 'Matthew 11:28-30',
                  translation: 'BSB',
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(EmojiFeedbackDialog), findsOneWidget);
      expect(find.text('How was your meditation?'), findsOneWidget);
      expect(find.text('SELECT YOUR EXPERIENCE'), findsOneWidget);

      // Verify emojis present
      expect(find.text('🕊️'), findsWidgets);
      expect(find.text('Peaceful'), findsOneWidget);
      expect(find.text('🙏'), findsWidgets);
      expect(find.text('Grateful'), findsOneWidget);
      expect(find.text('💛'), findsWidgets);
      expect(find.text('Comforted'), findsOneWidget);
      expect(find.text('😐'), findsWidgets);
      expect(find.text('Neutral'), findsOneWidget);
      expect(find.text('🌧️'), findsWidgets);
      expect(find.text('Distracted'), findsOneWidget);

      // Form inputs
      expect(find.byKey(const Key('feedback_comment_field')), findsOneWidget);
      expect(find.byKey(const Key('feedback_email_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_feedback_button')), findsOneWidget);
      expect(find.byKey(const Key('email_direct_button')), findsOneWidget);
    });

    testWidgets('Selects emoji, enters text, and submits reflection successfully', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EmojiFeedbackDialog.show(
                  context,
                  currentChapter: 'Romans 8:31-39',
                  translation: 'WEB',
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap grateful emoji (rating 4)
      await tester.tap(find.byKey(const Key('emoji_rating_4')));
      await tester.pumpAndSettle();

      // Enter comment
      await tester.enterText(
        find.byKey(const Key('feedback_comment_field')),
        'Loved the Romans 8 passage looping! Deep peace.',
      );
      await tester.enterText(
        find.byKey(const Key('feedback_email_field')),
        'sister@example.com',
      );
      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.byKey(const Key('submit_feedback_button')));
      await tester.pumpAndSettle();

      // Should show Thank You card
      expect(find.text('Thank You!'), findsOneWidget);
      expect(
        find.text('Your prayer and reflection help shape Selah for brothers and sisters around the world.'),
        findsOneWidget,
      );

      // Dismiss thank you dialog
      await tester.tap(find.text('Return to Meditation'));
      await tester.pumpAndSettle();

      expect(find.byType(EmojiFeedbackDialog), findsNothing);
    });

    testWidgets('Email direct button triggers copy to clipboard and SnackBar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EmojiFeedbackDialog.show(
                  context,
                  currentChapter: 'Psalm 23',
                  translation: 'BSB',
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_comment_field')),
        'Please add Psalm 91 next!',
      );
      await tester.pumpAndSettle();

      // Tap copy email button
      await tester.tap(find.byKey(const Key('email_direct_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Email template copied to clipboard!'), findsOneWidget);
      expect(find.textContaining('neilwarner+selah@gmail.com'), findsOneWidget);
    });

    testWidgets('SettingsBottomSheet includes button to open EmojiFeedbackDialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SettingsBottomSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final feedbackButton = find.byKey(const Key('open_feedback_dialog_button'));
      expect(feedbackButton, findsOneWidget);
      expect(find.text('Prayer, Reflection & Feedback'), findsOneWidget);
    });
  });
}
