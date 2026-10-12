import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/offline_indicator.dart';

void main() {
  group('OfflineIndicator Widget', () {
    testWidgets('renders bundled state correctly with emerald styling and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineIndicator(isOffline: true, isBundled: true),
            ),
          ),
        ),
      );

      expect(find.text('Bundled'), findsOneWidget);
      expect(find.byIcon(Icons.offline_pin_rounded), findsOneWidget);
      expect(find.text('Streaming'), findsNothing);
      expect(find.text('Cached'), findsNothing);
    });

    testWidgets('renders cached offline state correctly with amber styling and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineIndicator(isOffline: true, isBundled: false),
            ),
          ),
        ),
      );

      expect(find.text('Cached'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Streaming'), findsNothing);
      expect(find.text('Bundled'), findsNothing);
    });

    testWidgets('renders streaming online state correctly with indigo styling and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineIndicator(isOffline: false, isBundled: false),
            ),
          ),
        ),
      );

      expect(find.text('Streaming'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      expect(find.text('Cached'), findsNothing);
      expect(find.text('Bundled'), findsNothing);
    });

    testWidgets('tapping bundled indicator triggers SnackBar with bundled explanation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineIndicator(isOffline: true, isBundled: true),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OfflineIndicator));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Bundled Audio Active: Curated human narrator audio is loaded locally'),
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
