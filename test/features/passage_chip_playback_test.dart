// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter_test/flutter_test.dart';

import './step/the_app_is_open_signed_out.dart';
import './step/narrator_loads_finish_without_the_device_player.dart';
import './step/i_tap_the_passage_chip.dart';
import './step/the_heading_stays.dart';
import './step/the_passage_chip_is_selected.dart';
import './step/the_passage_chip_is_not_selected.dart';
import './step/playback_has_not_started.dart';
import './step/i_tap_the_play_control.dart';
import './step/playback_has_started.dart';
import './step/read_aloud_did_not_start.dart';

void main() {
  group('''A passage chip loads without starting playback''', () {
    testWidgets('''Tapping Matt loads it and stays paused until play''', (
      tester,
    ) async {
      await theAppIsOpenSignedOut(tester);
      await narratorLoadsFinishWithoutTheDevicePlayer(tester);
      await iTapThePassageChip(tester, 'Matt 11:28–30');
      await theHeadingStays(tester, 'Matt 11:28–30');
      await thePassageChipIsSelected(tester, 'Matt 11:28–30');
      await thePassageChipIsNotSelected(tester, '1 Cor 13:4–7');
      await playbackHasNotStarted(tester);
      await iTapThePlayControl(tester);
      await playbackHasStarted(tester);
      await readAloudDidNotStart(tester);
    });
  });
}
