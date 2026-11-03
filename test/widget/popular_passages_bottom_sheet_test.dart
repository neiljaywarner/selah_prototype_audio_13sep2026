import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/popular_passages_bottom_sheet.dart';

void main() {
  group('PopularPassagesBottomSheet Widget Tests', () {
    testWidgets('renders title, timeframe choice chips, and sort controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? selectedPassage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopularPassagesBottomSheet(
              onSelectPassage: (ref) => selectedPassage = ref,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Popular Passages'), findsOneWidget);
      expect(
        find.textContaining('Scriptures where fellow believers'),
        findsOneWidget,
      );

      // Timeframe chips
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      // Sort button
      expect(find.text('Meditators'), findsOneWidget);

      // Passages in list
      expect(find.text('1 Corinthians 13:4–7'), findsOneWidget);
      expect(find.text('Psalm 23'), findsOneWidget);
    });

    testWidgets('toggling sort changes sort label between Meditators and Loops',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopularPassagesBottomSheet(
              onSelectPassage: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meditators'), findsOneWidget);

      // Tap sort toggle
      await tester.tap(find.text('Meditators'));
      await tester.pumpAndSettle();

      expect(find.text('Loops'), findsOneWidget);

      // Tap sort toggle again
      await tester.tap(find.text('Loops'));
      await tester.pumpAndSettle();

      expect(find.text('Meditators'), findsOneWidget);
    });

    testWidgets('tapping a passage fires onSelectPassage callback with reference',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? selectedPassage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopularPassagesBottomSheet(
              onSelectPassage: (ref) => selectedPassage = ref,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Psalm 23
      await tester.tap(find.text('Psalm 23'));
      await tester.pumpAndSettle();

      expect(selectedPassage, equals('Psalm 23'));
    });

    testWidgets('reverence guardrails: no competitive rank numbers or badges',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopularPassagesBottomSheet(
              onSelectPassage: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No #1, Rank 1, or badge ranking
      expect(find.text('#1'), findsNothing);
      expect(find.text('Rank 1'), findsNothing);
      expect(find.text('Top Ranked'), findsNothing);
    });
  });
}
