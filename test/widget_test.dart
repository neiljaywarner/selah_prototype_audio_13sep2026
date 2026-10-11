import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';

void main() {
  testWidgets('SelahApp v0.2 UI smoke test renders all essential components', (WidgetTester tester) async {
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

    // Verify Search Bar and Autocomplete
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Jn');
    await tester.pump();

    // Autocomplete chips for John and Jonah should appear (may have >1 text widget per chip)
    expect(find.text('John 1'), findsWidgets);
    expect(find.text('Jonah 1'), findsWidgets);

    // Verify Audio Mode Pill
    expect(find.textContaining('Human Narrator'), findsOneWidget);

    // Tap Feature Voting Button and verify bottom sheet appears
    await tester.tap(find.byIcon(Icons.how_to_vote_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Feature Roadmap & Feedback'), findsOneWidget);
    expect(find.text('COMMUNITY FEATURE VOTING'), findsOneWidget);
  });
}
