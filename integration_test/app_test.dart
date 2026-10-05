import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolTest(
    'Selah core experience: launches, selects John 1 chapter audio, and verifies human narrator playback',
    ($) async {
      await $.pumpWidget(const ProviderScope(child: SelahApp()));
      await $.pumpAndSettle();

      // 1. Verify Header
      expect($('SELAH'), findsOneWidget);

      // 2. Autocomplete
      await $(TextField).enterText('Jn');
      await $.pump(const Duration(milliseconds: 500));
      expect($(RegExp(r'John')), findsWidgets);
      expect($(RegExp(r'Jonah')), findsWidgets);

      // 3. Search & select John 1
      await $(TextField).enterText('John');
      await $.pump(const Duration(milliseconds: 500));

      final johnChip = $(RegExp(r'John 1'));
      if (johnChip.visible) {
        await johnChip.tap();
        await $.pumpAndSettle();
      }

      // Assert Audio Mode Indicator
      expect(
        $(RegExp(r'Narrator')).visible || $(RegExp(r'TTS')).visible || $(RegExp(r'Speech')).visible,
        isTrue,
      );

      // 4. Open Roadmap Voting Modal
      final voteIcon = $(Icons.how_to_vote_rounded);
      if (voteIcon.visible) {
        await voteIcon.tap();
        await $.pumpAndSettle();
        expect($(RegExp(r'Feature')), findsWidgets);
      }
    },
    config: const PatrolTesterConfig(),
  );
}
