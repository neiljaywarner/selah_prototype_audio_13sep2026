// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/the_passage_playing_is.dart';
import './step/i_share_the_current_passage.dart';
import './step/the_share_link_contains.dart';
import './step/the_share_payload_contains.dart';
import './step/the_share_payload_contains_the_verse.dart';
import './step/the_share_message_contains.dart';
import './step/the_share_message_does_not_contain.dart';
import './step/read_aloud_did_not_start.dart';
import './step/i_have_in_my_passages.dart';
import './step/i_share_from_my_passages.dart';
import './step/the_passage_playing_is_in.dart';
import './step/i_play_the_shared_passage.dart';
import './step/esv_lookups_return.dart';
import './step/the_onscreen_text_includes.dart';
import './step/the_share_payload_does_not_contain_the_verse.dart';
import './step/the_share_sheet_will_fail.dart';
import './step/i_see_a_share_failure.dart';
import './step/i_open_the_share_link_while_signed_out.dart';
import './step/i_see_the_passage.dart';
import './step/i_can_start_playback.dart';
import './step/listening_session_chrome_is_shown.dart';
import './step/i_am_not_asked_to_sign_in.dart';
import './step/i_see_a_friendly_passage_error.dart';
import './step/the_player_is_not_blank.dart';
import './step/saving_the_passage_is_unavailable.dart';
import './step/playback_is_unavailable.dart';
import './step/listening_session_chrome_is_hidden.dart';
import './step/i_choose_the_translation.dart';
import './step/i_open_the_share_link_in_while_signed_out.dart';

void main() {
  group('''Share a passage''', () {
    testWidgets('''Sharing the passage that is playing''', (tester) async {
      await thePassagePlayingIs(tester, '1 Cor 13:4-7');
      await iShareTheCurrentPassage(tester);
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=1+Cor+13:4-7');
      await theSharePayloadContains(tester, '1 Cor 13:4-7');
      await theSharePayloadContainsTheVerse(
          tester, 'Love is patient, love is kind');
      await theShareMessageContains(tester, '(BSB)');
      await theShareMessageContains(
          tester, 'Public Domain · Narrator: Barry Hays');
      await theShareMessageDoesNotContain(tester, 'Crossway');
      await readAloudDidNotStart(tester);
    });
    testWidgets('''Sharing a passage from My Passages''', (tester) async {
      await iHaveInMyPassages(tester, '1 Cor 13:4-7');
      await iShareFromMyPassages(tester, '1 Cor 13:4-7');
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=1+Cor+13:4-7');
      await theSharePayloadContains(tester, '1 Cor 13:4-7');
      await theSharePayloadContainsTheVerse(
          tester, 'Love is patient, love is kind');
      await theShareMessageContains(tester, '(BSB)');
      await readAloudDidNotStart(tester);
    });
    testWidgets('''Sharing loaded ESV words''', (tester) async {
      await thePassagePlayingIsIn(tester, 'John 16:32-33', 'ESV');
      await iPlayTheSharedPassage(tester);
      await iShareTheCurrentPassage(tester);
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=John+16:32-33');
      await theSharePayloadContains(tester, 'John 16:32-33');
      await theSharePayloadContainsTheVerse(tester, 'verse thirty-two only');
      await theSharePayloadContainsTheVerse(tester, 'verse thirty-three only');
      await theShareMessageContains(tester, '(ESV)');
      await theShareMessageContains(tester, 'Crossway');
      await readAloudDidNotStart(tester);
    });
    testWidgets('''A long ESV range shares the reference without the verse''',
        (tester) async {
      await thePassagePlayingIsIn(tester, '2 John 1:1-13', 'ESV');
      await esvLookupsReturn(tester, 'Placeholder line only.');
      await iPlayTheSharedPassage(tester);
      await theOnscreenTextIncludes(tester, 'Placeholder line only.');
      await iShareTheCurrentPassage(tester);
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=2+John+1:1-13');
      await theSharePayloadContains(tester, '2 John 1:1-13');
      await theSharePayloadDoesNotContainTheVerse(
          tester, 'Placeholder line only.');
      await theShareMessageContains(tester, '2 John 1:1-13');
      await readAloudDidNotStart(tester);
    });
    testWidgets('''Sharing when the words are not loaded''', (tester) async {
      await thePassagePlayingIs(tester, 'John 3:16');
      await iShareTheCurrentPassage(tester);
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=John+3:16');
      await theSharePayloadContains(tester, 'John 3:16');
      await theSharePayloadDoesNotContainTheVerse(
          tester, 'Press play to listen');
      await readAloudDidNotStart(tester);
    });
    testWidgets('''Sharing a saved passage that is not on screen''',
        (tester) async {
      await iHaveInMyPassages(tester, 'John 3:16');
      await iShareFromMyPassages(tester, 'John 3:16');
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=John+3:16');
      await theSharePayloadContains(tester, 'John 3:16');
      await theSharePayloadDoesNotContainTheVerse(
          tester, 'Love is patient, love is kind');
      await readAloudDidNotStart(tester);
    });
    testWidgets('''NIV shares do not paste the verse''', (tester) async {
      await thePassagePlayingIsIn(tester, '1 Cor 13:4-7', 'NIV');
      await iShareTheCurrentPassage(tester);
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=1+Cor+13:4-7');
      await theSharePayloadContains(tester, '1 Cor 13:4-7');
      await theSharePayloadDoesNotContainTheVerse(
          tester, 'Love is patient, love is kind');
      await theShareMessageContains(tester, 'NIV');
      await readAloudDidNotStart(tester);
    });
    testWidgets('''ESV does not share another translation's words''',
        (tester) async {
      await thePassagePlayingIsIn(tester, '1 Cor 13:4-7', 'ESV');
      await iShareTheCurrentPassage(tester);
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=1+Cor+13:4-7');
      await theSharePayloadContains(tester, '1 Cor 13:4-7');
      await theSharePayloadDoesNotContainTheVerse(
          tester, 'Love is patient, love is kind');
      await readAloudDidNotStart(tester);
    });
    testWidgets('''A failed share does not say the link is ready''',
        (tester) async {
      await thePassagePlayingIs(tester, '1 Cor 13:4-7');
      await theShareSheetWillFail(tester);
      await iShareTheCurrentPassage(tester);
      await iSeeAShareFailure(tester);
    });
    testWidgets('''Opening a shared passage without an account''',
        (tester) async {
      await iOpenTheShareLinkWhileSignedOut(tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=1+Cor+13:4-7');
      await iSeeThePassage(tester, '1 Cor 13:4-7');
      await iCanStartPlayback(tester);
      await listeningSessionChromeIsShown(tester);
      await iAmNotAskedToSignIn(tester);
    });
    testWidgets('''A broken share link shows a friendly error''',
        (tester) async {
      await iOpenTheShareLinkWhileSignedOut(tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=NotABook+99:1');
      await iSeeAFriendlyPassageError(tester);
      await thePlayerIsNotBlank(tester);
      await savingThePassageIsUnavailable(tester);
      await playbackIsUnavailable(tester);
      await listeningSessionChromeIsHidden(tester);
      await iAmNotAskedToSignIn(tester);
      await iChooseTheTranslation(tester, 'WEB');
      await iSeeAFriendlyPassageError(tester);
      await savingThePassageIsUnavailable(tester);
      await listeningSessionChromeIsHidden(tester);
    });
    testWidgets('''A broken ESV link hides listening chrome''', (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=NotABook+99:1',
          'ESV');
      await iSeeAFriendlyPassageError(tester);
      await listeningSessionChromeIsHidden(tester);
    });
  });
}
