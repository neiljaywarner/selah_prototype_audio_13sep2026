import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/offline_indicator.dart';

void main() {
  group('OfflineIndicator Widget', () {
    testWidgets('renders offline state correctly with amber styling and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineIndicator(isOffline: true),
            ),
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    });

    testWidgets('renders online state correctly with green styling and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineIndicator(isOffline: false),
            ),
          ),
        ),
      );

      expect(find.text('Online'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('tapping offline indicator triggers SnackBar with explanation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineIndicator(isOffline: true),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OfflineIndicator));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Offline Mode Active: Curated human narrator audio and text are loaded locally'),
        findsOneWidget,
      );
    });

    testWidgets('custom onTap callback is called when provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineIndicator(
                isOffline: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OfflineIndicator));
      expect(tapped, isTrue);
    });
  });
}
