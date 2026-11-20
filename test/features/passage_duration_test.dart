// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter_test/flutter_test.dart';

import './step/i_have_in_my_passages.dart';
import './step/the_next_narrator_load_reports_seconds.dart';
import './step/i_tap_the_passage_chip.dart';
import './step/the_duration_bar_shows.dart';
import './step/my_passages_lists.dart';
import './step/i_open_from_my_passages.dart';
import './step/i_see_the_passage.dart';
import './step/the_passage_chip_is_not_selected.dart';

void main() {
  group('''Passage duration follows the loaded passage''', () {
    testWidgets(
      '''Reopening a saved passage drops the previous clip length''',
      (tester) async {
        await iHaveInMyPassages(tester, 'John 3:16-18');
        await theNextNarratorLoadReportsSeconds(tester, '17');
        await iTapThePassageChip(tester, 'Matt 11:28–30');
        await theDurationBarShows(tester, '00:17');
        await myPassagesLists(tester, 'John 3:16-18');
        await iOpenFromMyPassages(tester, 'John 3:16-18');
        await iSeeThePassage(tester, 'John 3:16-18');
        await theDurationBarShows(tester, '00:00');
        await thePassageChipIsNotSelected(tester, 'Matt 11:28–30');
      },
    );
  });
}
