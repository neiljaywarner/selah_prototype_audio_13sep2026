import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';

void main() {
  testWidgets('SelahApp v0.2 UI smoke test renders all essential components', (WidgetTester tester) async {
    // Set a large enough surface size so widgets don't overflow
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: SelahApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('SELAH'), findsOneWidget);
    expect(find.text('Scripture Audio Meditation v0.2'), findsOneWidget);

    // Verify Action Icons
    expect(find.byIcon(Icons.how_to_vote_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);

    // Verify Topic Tabs
    expect(find.textContaining('Hope'), findsOneWidget);
    expect(find.textContaining('Faith'), findsOneWidget);
    expect(find.textContaining('Peace'), findsOneWidget);

    // Verify Audio Mode Pill
    expect(find.textContaining('Human Narrator'), findsOneWidget);

    // Tap Feature Voting Button and verify bottom sheet appears
    await tester.tap(find.byIcon(Icons.how_to_vote_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Feature Roadmap & Feedback'), findsOneWidget);
    expect(find.text('COMMUNITY FEATURE VOTING'), findsOneWidget);
  });
}
