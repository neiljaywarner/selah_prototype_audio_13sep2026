import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

void main() {
  group('Player Attribution and Licensing UI Tests (#26 / #31 with Patrol Finders)', () {
    patrolWidgetTest('renders visible attribution button and opens licensing sheet using Patrol Finders', ($) async {
      await $.tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => $.tester.binding.setSurfaceSize(null));

      await $.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChapterPlayerScreen(),
          ),
        ),
      );

      // Verify the player attribution button is present using Patrol symbol key finder
      expect($(#player_attribution_button), findsOneWidget);

      // Verify short attribution text with Patrol text finder
      expect($('Public Domain · Narrator: Barry Hays'), findsOneWidget);

      // Tap attribution button using Patrol tap
      await $(#player_attribution_button).tap();

      // Verify the bottom sheet modal opens with all key licensing sections
      expect($('Scripture & Audio Licensing'), findsOneWidget);
      expect($('Text & Scripture Rights'), findsOneWidget);
      expect($('Narrator & Audio Production'), findsOneWidget);
      expect($('API.Bible & FUMS Fair Use Compliance'), findsOneWidget);
      expect($('Offline Boundaries & Local Cache'), findsOneWidget);

      // Dismiss the modal using Patrol finder and tap
      expect($(#close_attribution_details_button), findsOneWidget);
      await $(#close_attribution_details_button).tap();

      // Verify modal is closed
      expect($('Scripture & Audio Licensing'), findsNothing);
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
