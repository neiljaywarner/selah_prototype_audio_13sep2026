import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/passage_timing_feedback_bar.dart';

void main() {
  Future<void> showBar(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PassageTimingFeedbackBar(
            passageTitle: 'Psalm 23',
            translationCode: 'BSB',
          ),
        ),
      ),
    );
    expect(find.text('Audio & timing peaceful?'), findsOneWidget);
  }

  testWidgets('A peaceful rating is acknowledged', (tester) async {
    await showBar(tester);
    await tester.tap(find.byTooltip('Audio and timing are good'));
    await tester.pumpAndSettle();
    expect(find.text('Saved 🕊️'), findsOneWidget);
    expect(find.textContaining('Thank you! Glad the audio was peaceful.'), findsOneWidget);
  });

  testWidgets('A problem report offers calibration choices', (tester) async {
    await showBar(tester);
    await tester.tap(find.byTooltip('Report audio timing or clipping issue'));
    await tester.pumpAndSettle();
    expect(find.text('Audio & Timing Calibration'), findsOneWidget);
    expect(find.text('Started too early or cut into words'), findsOneWidget);
    expect(find.text('Psalm 23 (BSB)'), findsOneWidget);
  });

  testWidgets('Missing timestamps offers to request an alignment', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PassageTimingFeedbackBar(
            passageTitle: 'Revelation 21:1-4',
            translationCode: 'BSB',
            hasTimestamps: false,
          ),
        ),
      ),
    );
    expect(find.textContaining('Request'), findsWidgets);
    await tester.tap(find.textContaining('Request').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('notified the devs'), findsOneWidget);
  });
}
