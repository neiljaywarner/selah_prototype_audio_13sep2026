import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/emoji_feedback_dialog.dart';

void main() {
  group('EmojiFeedbackDialog Streamlined Peaceful Tests (#175)', () {
    testWidgets('Renders 3 sentiment options and default Loving it! experience', (WidgetTester tester) async {
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
      expect(find.text('Prayer & Feedback'), findsOneWidget);
      expect(find.text('HOW IS YOUR MEDITATION EXPERIENCE?'), findsOneWidget);

      // Verify 3 sentiment options present
      expect(find.text('😊'), findsWidgets);
      expect(find.text('Loving it!'), findsOneWidget);
      expect(find.text('💡'), findsWidgets);
      expect(find.text('Suggestion'), findsOneWidget);
      expect(find.text('🛠️'), findsWidgets);
      expect(find.text('Needs work'), findsOneWidget);

      // Form inputs
      expect(find.byKey(const Key('feedback_comment_field')), findsOneWidget);
      expect(find.byKey(const Key('feedback_email_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_feedback_button')), findsOneWidget);
      expect(find.text('Send Blessing & Praise'), findsOneWidget);
      expect(find.byKey(const Key('screenshot_feedback_button')), findsOneWidget);

      // Verify developer plumbing & email clipboard buttons are removed
      expect(find.byKey(const Key('email_direct_button')), findsNothing);
      expect(find.textContaining('Tell Neil'), findsNothing);
    });

    testWidgets('Selecting Suggestion updates hint text and button label', (WidgetTester tester) async {
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

      // Tap Suggestion option
      await tester.tap(find.byKey(const Key('face_option_neutral')));
      await tester.pumpAndSettle();

      expect(find.text('Send Suggestion'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byKey(const Key('feedback_comment_field')));
      expect(textField.decoration?.hintText, contains('What features or passages would help your meditation?'));
    });

    testWidgets('Submitting feedback displays peaceful confirmation and returns', (WidgetTester tester) async {
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
                  currentChapter: '1 Corinthians 13:4-7',
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

      // Tap Needs work
      await tester.tap(find.byKey(const Key('face_option_sad')));
      await tester.pumpAndSettle();

      expect(find.text('Send Feedback'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('feedback_comment_field')),
        'The audio timing seems slightly delayed in verse 4.',
      );
      await tester.enterText(
        find.byKey(const Key('feedback_email_field')),
        'seeker@example.com',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_feedback_button')));
      await tester.pumpAndSettle();

      expect(find.text('Thank You!'), findsOneWidget);
      expect(find.textContaining('Your note has been received with care'), findsOneWidget);

      await tester.tap(find.byKey(const Key('return_to_meditation_button')));
      await tester.pumpAndSettle();

      expect(find.byType(EmojiFeedbackDialog), findsNothing);
    });
  });
}
