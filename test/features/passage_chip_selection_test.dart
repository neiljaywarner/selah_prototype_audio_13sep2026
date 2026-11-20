// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter_test/flutter_test.dart';

import './step/i_open_the_share_link_while_signed_out.dart';
import './step/i_see_the_passage.dart';
import './step/the_passage_chip_is_not_selected.dart';
import './step/the_passage_chip_is_selected.dart';

void main() {
  group('''Passage chip selection follows the loaded reference''', () {
    testWidgets('''A John link does not leave 1 Cor selected''', (
      tester,
    ) async {
      await iOpenTheShareLinkWhileSignedOut(
        tester,
        'https://selahword.web.app/?ref=John+3:16-18',
      );
      await iSeeThePassage(tester, 'John 3:16-18');
      await thePassageChipIsNotSelected(tester, '1 Cor 13:4–7');
      await thePassageChipIsNotSelected(tester, 'Matt 11:28–30');
      await thePassageChipIsNotSelected(tester, 'Rom 8:31–39');
      await thePassageChipIsNotSelected(tester, 'Psalm 23');
    });
    testWidgets(
      '''The matching curated chip is selected from a hyphenated link''',
      (tester) async {
        await iOpenTheShareLinkWhileSignedOut(
          tester,
          'https://selahword.web.app/?ref=1+Cor+13:4-7',
        );
        await iSeeThePassage(tester, '1 Cor 13:4-7');
        await thePassageChipIsSelected(tester, '1 Cor 13:4–7');
        await thePassageChipIsNotSelected(tester, 'Matt 11:28–30');
        await thePassageChipIsNotSelected(tester, 'Psalm 23');
      },
    );
    testWidgets(
      '''A different range on the same chapter does not select the curated chip''',
      (tester) async {
        await iOpenTheShareLinkWhileSignedOut(
          tester,
          'https://selahword.web.app/?ref=1+Cor+13:8-13',
        );
        await iSeeThePassage(tester, '1 Cor 13:8-13');
        await thePassageChipIsNotSelected(tester, '1 Cor 13:4–7');
        await thePassageChipIsNotSelected(tester, 'Matt 11:28–30');
      },
    );
  });
}
