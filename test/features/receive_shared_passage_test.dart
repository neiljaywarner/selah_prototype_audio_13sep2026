// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_open_the_share_link_while_signed_out.dart';
import './step/i_see_the_passage.dart';
import './step/i_do_not_see_the_curated_wording.dart';
import './step/i_play_the_shared_passage.dart';
import './step/i_am_asked_before_the_passage_is_read_aloud.dart';
import './step/text_to_speech_has_not_started.dart';
import './step/the_onscreen_text_is_the_shared_bsb_range.dart';
import './step/the_heading_stays.dart';
import './step/playback_is_the_shared_range_and_not_the_full_chapter.dart';
import './step/i_decline_read_aloud.dart';
import './step/the_passage_is_not_read_aloud.dart';
import './step/i_choose_the_translation.dart';
import './step/the_placeholder_is_not_spoken.dart';

void main() {
  group('''Receive a shared passage on BSB''', () {
    testWidgets('''Psalm 62:5-7 does not show the curated 62:1-2 text''',
        (tester) async {
      await iOpenTheShareLinkWhileSignedOut(tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=Psalm+62:5-7');
      await iSeeThePassage(tester, 'Psalm 62:5-7');
      await iDoNotSeeTheCuratedWording(
          tester, 'My soul finds rest in God alone');
      await iPlayTheSharedPassage(tester);
      await iAmAskedBeforeThePassageIsReadAloud(tester);
      await textToSpeechHasNotStarted(tester);
      await theOnscreenTextIsTheSharedBsbRange(
          tester, 'Rest in God alone, O my soul');
      await iDoNotSeeTheCuratedWording(
          tester, 'My soul finds rest in God alone');
      await iDoNotSeeTheCuratedWording(tester, 'I will never be shaken');
      await theHeadingStays(tester, 'Psalm 62:5-7');
      await playbackIsTheSharedRangeAndNotTheFullChapter(tester);
      await iDeclineReadAloud(tester);
      await thePassageIsNotReadAloud(tester);
      await iChooseTheTranslation(tester, 'WEB');
      await theHeadingStays(tester, 'Psalm 62:5-7');
      await iDoNotSeeTheCuratedWording(tester, 'Rest in God alone');
      await thePlaceholderIsNotSpoken(tester);
    });
    testWidgets(
        '''A different range on a curated chapter does not use that excerpt''',
        (tester) async {
      await iOpenTheShareLinkWhileSignedOut(tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=1+Cor+13:8-13');
      await iSeeThePassage(tester, '1 Cor 13:8-13');
      await iDoNotSeeTheCuratedWording(tester, 'Love is patient, love is kind');
      await iPlayTheSharedPassage(tester);
      await iSeeThePassage(tester, '1 Cor 13:8-13');
      await iDoNotSeeTheCuratedWording(tester, 'Love is patient, love is kind');
      await iDoNotSeeTheCuratedWording(
          tester, 'bears all things, believes all things');
    });
  });
}
