import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/emoji_feedback_dialog.dart';

void main() {
  group('EmojiFeedbackDialog 3-Face Funnel Widget Tests (#55)', () {
    testWidgets('Renders 3 sentiment faces (Happy, Neutral, Sad) and default happy funnel', (WidgetTester tester) async {
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
      expect(find.text('How do you like Selah?'), findsOneWidget);
      expect(find.text('SELECT YOUR APP EXPERIENCE'), findsOneWidget);

      // Verify 3 faces present
      expect(find.text('😊'), findsWidgets);
      expect(find.text('Loving it!'), findsOneWidget);
      expect(find.text('😐'), findsWidgets);
      expect(find.text('It is okay'), findsOneWidget);
      expect(find.text('😞'), findsWidgets);
      expect(find.text('Needs work'), findsOneWidget);

      // Default happy funnel encourages 4-5 stars
      expect(find.textContaining('Would you rate Selah 4 or 5 stars?'), findsOneWidget);
      expect(find.byKey(const Key('rating_star_4')), findsOneWidget);
      expect(find.byKey(const Key('rating_star_5')), findsOneWidget);

      // Form inputs
      expect(find.byKey(const Key('feedback_comment_field')), findsOneWidget);
      expect(find.byKey(const Key('feedback_email_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_feedback_button')), findsOneWidget);
      expect(find.byKey(const Key('email_direct_button')), findsOneWidget);
    });

    testWidgets('Selecting Neutral face funnels to private pre-triage message', (WidgetTester tester) async {
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

      // Tap neutral face
      await tester.tap(find.byKey(const Key('face_option_neutral')));
      await tester.pumpAndSettle();

      // Funnel should show private pre-triage
      expect(find.textContaining('Private Pre-Triage: Help us make Selah more peaceful'), findsOneWidget);
      expect(find.text('Submit Private Feedback'), findsOneWidget);
      expect(find.text('Email Neil Directly (Private)'), findsOneWidget);
    });

    testWidgets('Selecting Sad face funnels to private bug/frustration message and submits', (WidgetTester tester) async {
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

      // Tap sad face
      await tester.tap(find.byKey(const Key('face_option_sad')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Private Pre-Triage: Tell Neil what felt frustrating or broken'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('feedback_comment_field')),
        'The audio stream paused when I locked the screen.',
      );
      await tester.enterText(
        find.byKey(const Key('feedback_email_field')),
        'tester@example.com',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_feedback_button')));
      await tester.pumpAndSettle();

      expect(find.text('Thank You for Your Feedback!'), findsOneWidget);
      expect(find.textContaining('safely recorded in our private triage inbox'), findsOneWidget);

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

      // Switch to neutral to show the private pre-triage funnel
      await tester.tap(find.byKey(const Key('face_option_neutral')));
      await tester.pumpAndSettle();

      final emailButton = find.byKey(const Key('email_direct_button'));
      await tester.ensureVisible(emailButton);
      await tester.tap(emailButton);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('neilwarner+selah@gmail.com'), findsOneWidget);
    });
  });
}
