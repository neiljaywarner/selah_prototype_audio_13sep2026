import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

void main() {
  group('Player Attribution and Licensing UI Tests (#26)', () {
    testWidgets('renders visible attribution button and opens licensing sheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChapterPlayerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the player attribution button is present
      final attrButton = find.byKey(const Key('player_attribution_button'));
      expect(attrButton, findsOneWidget);

      // Verify the short attribution text is displayed
      expect(find.textContaining('Public Domain · Narrator: Barry Hays'), findsOneWidget);

      // Tap attribution button to open the bottom sheet modal
      await tester.tap(attrButton);
      await tester.pumpAndSettle();

      // Verify the bottom sheet opened with all key licensing sections
      expect(find.text('Scripture & Audio Licensing'), findsOneWidget);
      expect(find.text('Text & Scripture Rights'), findsOneWidget);
      expect(find.text('Narrator & Audio Production'), findsOneWidget);
      expect(find.text('API.Bible & FUMS Fair Use Compliance'), findsOneWidget);
      expect(find.text('Offline Boundaries & Local Cache'), findsOneWidget);

      // Verify dismiss button works cleanly
      final closeButton = find.byKey(const Key('close_attribution_details_button'));
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify modal is closed
      expect(find.text('Scripture & Audio Licensing'), findsNothing);
    });

    test('BibleTranslation model provides valid attribution metadata for all translations', () {
      for (final translation in BibleTranslation.values) {
        expect(translation.shortAttribution.isNotEmpty, isTrue);
        expect(translation.narratorCredit.isNotEmpty, isTrue);
        expect(translation.audioLicensingTerms.isNotEmpty, isTrue);
        expect(translation.badgeLabel.isNotEmpty, isTrue);
      }
      expect(BibleTranslation.niv.isLicensed, isTrue);
      expect(BibleTranslation.bsb.isLicensed, isFalse);
      expect(BibleTranslation.web.isLicensed, isFalse);
    });
  });
}
