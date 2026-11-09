// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_open_the_share_link_in_while_signed_out.dart';
import './step/i_see_the_passage.dart';
import './step/i_play_the_shared_passage.dart';
import './step/i_am_asked_before_the_passage_is_read_aloud.dart';
import './step/text_to_speech_has_not_started.dart';
import './step/the_onscreen_text_includes.dart';
import './step/i_do_not_see_the_curated_wording.dart';
import './step/the_heading_stays.dart';
import './step/i_confirm_read_aloud.dart';
import './step/i_decline_read_aloud.dart';
import './step/the_passage_is_read_aloud.dart';
import './step/the_passage_is_not_read_aloud.dart';
import './step/the_attribution_includes.dart';
import './step/i_see_verse_timing_marked_unaligned.dart';
import './step/i_choose_the_translation.dart';
import './step/the_esv_passage_requests_include.dart';
import './step/the_esv_passage_requests_do_not_include.dart';
import './step/the_heading_stays_on.dart';
import './step/i_do_not_see_verse_timing_marked_unaligned.dart';
import './step/the_passage_playing_is_in.dart';
import './step/i_search_for.dart';
import './step/i_turn_on_apibible_narrator_translations.dart';
import './step/esv_lookups_are_held.dart';
import './step/esv_lookups_continue.dart';
import './step/the_placeholder_is_not_spoken.dart';
import './step/the_human_narrator_chip_is_hidden.dart';
import './step/the_human_narrator_chip_is_shown.dart';
import './step/i_load_the_featured_passage_while_the_question_is_open.dart';
import './step/read_aloud_was_not_confirmed.dart';

void main() {
  group('''Receive John 16:32-33''', () {
    testWidgets('''An old read-aloud answer does not speak the next passage''',
        (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33',
          'BSB');
      await iPlayTheSharedPassage(tester);
      await iAmAskedBeforeThePassageIsReadAloud(tester);
      await iLoadTheFeaturedPassageWhileTheQuestionIsOpen(tester, '1 Cor 13:4');
      await iConfirmReadAloud(tester);
      await theOnscreenTextIncludes(tester, 'Love is patient');
      await iDoNotSeeTheCuratedWording(tester, 'Look, an hour is coming');
      await readAloudWasNotConfirmed(tester);
    });
    testWidgets('''BSB reads John 16:32-33 aloud''', (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33',
          'BSB');
      await iSeeThePassage(tester, 'John 16:32-33');
      await iPlayTheSharedPassage(tester);
      await iAmAskedBeforeThePassageIsReadAloud(tester);
      await theOnscreenTextIncludes(tester, 'Ask for verse timing');
      await iDoNotSeeTheCuratedWording(tester, 'Request from devs');
      await textToSpeechHasNotStarted(tester);
      await theOnscreenTextIncludes(tester, 'Look, an hour is coming');
      await theOnscreenTextIncludes(tester, 'take courage');
      await iDoNotSeeTheCuratedWording(tester, 'For God so loved the world');
      await iDoNotSeeTheCuratedWording(tester, 'In the beginning was the Word');
      await theHeadingStays(tester, 'John 16:32-33');
      await iConfirmReadAloud(tester);
      await thePassageIsReadAloud(tester);
      await theAttributionIncludes(tester, 'Barry Hays');
      await iSeeVerseTimingMarkedUnaligned(tester);
    });
    testWidgets('''WEB reads John 16:32-33 aloud''', (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33',
          'BSB');
      await iChooseTheTranslation(tester, 'WEB');
      await iAmAskedBeforeThePassageIsReadAloud(tester);
      await textToSpeechHasNotStarted(tester);
      await theOnscreenTextIncludes(tester, 'Behold, the time is coming');
      await theOnscreenTextIncludes(tester, 'cheer up');
      await iDoNotSeeTheCuratedWording(tester, 'Look, an hour is coming');
      await iDoNotSeeTheCuratedWording(tester, 'For God so loved the world');
      await theHeadingStays(tester, 'John 16:32-33');
      await iConfirmReadAloud(tester);
      await thePassageIsReadAloud(tester);
      await theAttributionIncludes(tester, 'Hosanna');
      await iSeeVerseTimingMarkedUnaligned(tester);
    });
    testWidgets('''Declining the read aloud leaves John 16 quiet''', (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33',
          'BSB');
      await iPlayTheSharedPassage(tester);
      await iAmAskedBeforeThePassageIsReadAloud(tester);
      await theHumanNarratorChipIsHidden(tester);
      await iDeclineReadAloud(tester);
      await thePassageIsNotReadAloud(tester);
      await theHumanNarratorChipIsShown(tester);
      await theHeadingStays(tester, 'John 16:32-33');
      await theOnscreenTextIncludes(tester, 'Look, an hour is coming');
    });
    testWidgets('''Declining read aloud keeps the narrator notice''', (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33',
          'BSB');
      await iPlayTheSharedPassage(tester);
      await iAmAskedBeforeThePassageIsReadAloud(tester);
      await theOnscreenTextIncludes(tester, 'Narrator stream unavailable');
      await iDeclineReadAloud(tester);
      await thePassageIsNotReadAloud(tester);
      await theOnscreenTextIncludes(tester, 'Narrator stream unavailable');
      await iDoNotSeeTheCuratedWording(tester, 'Verse timing for');
    });
    testWidgets('''ESV requests John 16:32 and John 16:33''', (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33',
          'ESV');
      await iSeeThePassage(tester, 'John 16:32-33');
      await iPlayTheSharedPassage(tester);
      await theEsvPassageRequestsInclude(tester, 'John 16:32');
      await theEsvPassageRequestsInclude(tester, 'John 16:33');
      await theEsvPassageRequestsDoNotInclude(tester, 'John 3:16');
      await theOnscreenTextIncludes(tester, 'verse thirty-two only');
      await theOnscreenTextIncludes(tester, 'verse thirty-three only');
      await theHeadingStaysOn(tester, 'John 16:32-33');
      await theAttributionIncludes(tester, 'Crossway');
      await iDoNotSeeVerseTimingMarkedUnaligned(tester);
    });
    testWidgets('''An ESV search replaces the previous range''', (tester) async {
      await thePassagePlayingIsIn(tester, 'Psalm 62:5-7', 'ESV');
      await iSearchFor(tester, 'John 16:32-33');
      await iTurnOnApibibleNarratorTranslations(tester);
      await iChooseTheTranslation(tester, 'BSB');
      await theHeadingStays(tester, 'John 16:32-33');
      await theOnscreenTextIncludes(tester, 'Look, an hour is coming');
      await iDoNotSeeTheCuratedWording(tester, 'Rest in God alone');
    });
    testWidgets('''A later translation wins over a slow ESV search''', (tester) async {
      await thePassagePlayingIsIn(tester, 'Psalm 62:5-7', 'ESV');
      await esvLookupsAreHeld();
      await iSearchFor(tester, 'John 16:32-33');
      await iTurnOnApibibleNarratorTranslations(tester);
      await iChooseTheTranslation(tester, 'BSB');
      await esvLookupsContinue(tester);
      await theHeadingStays(tester, 'Psalm 62:5-7');
      await theOnscreenTextIncludes(tester, 'Rest in God alone');
      await iDoNotSeeTheCuratedWording(tester, 'verse thirty-two only');
    });
    testWidgets('''A missing passage is not read from the placeholder''', (tester) async {
      await thePassagePlayingIsIn(tester, 'Psalm 62:5-7', 'WEB');
      await iPlayTheSharedPassage(tester);
      await thePlaceholderIsNotSpoken(tester);
      await theOnscreenTextIncludes(tester, 'The words for this passage are not loaded');
      await theHeadingStays(tester, 'Psalm 62:5-7');
    });
  });
}
