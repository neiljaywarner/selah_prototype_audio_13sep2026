// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter_test/flutter_test.dart';

import './step/the_passage_playing_is.dart';
import './step/i_save_the_passage_to_my_passages.dart';
import './step/my_passages_lists.dart';
import './step/i_open_from_my_passages.dart';
import './step/i_see_the_passage.dart';
import './step/the_open_range_is_verses_through.dart';
import './step/i_can_start_playback.dart';
import './step/read_aloud_did_not_start.dart';

void main() {
  group('''My passages keeps the exact range''', () {
    testWidgets('''A saved range stays exact and reopens on the narrator''', (
      tester,
    ) async {
      await thePassagePlayingIs(tester, '1 Cor 13:4-7');
      await iSaveThePassageToMyPassages(tester);
      await myPassagesLists(tester, '1 Cor 13:4-7');
      await iOpenFromMyPassages(tester, '1 Cor 13:4-7');
      await iSeeThePassage(tester, '1 Cor 13:4-7');
      await theOpenRangeIsVersesThrough(tester, '4', '7');
      await iCanStartPlayback(tester);
      await readAloudDidNotStart(tester);
    });
  });
}
