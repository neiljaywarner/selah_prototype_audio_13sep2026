// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/the_passage_playing_is.dart';
import './step/i_share_the_current_passage.dart';
import './step/the_share_link_contains.dart';
import './step/the_share_payload_contains.dart';
import './step/the_share_payload_does_not_contain_the_verse.dart';
import './step/the_share_sheet_will_fail.dart';
import './step/i_see_a_share_failure.dart';
import './step/i_have_in_my_passages.dart';
import './step/i_share_from_my_passages.dart';
import './step/i_open_the_share_link_while_signed_out.dart';
import './step/i_see_the_passage.dart';
import './step/i_can_start_playback.dart';
import './step/i_am_not_asked_to_sign_in.dart';
import './step/i_see_a_friendly_passage_error.dart';
import './step/the_player_is_not_blank.dart';
import './step/saving_the_passage_is_unavailable.dart';
import './step/playback_is_unavailable.dart';
import './step/listening_session_chrome_is_hidden.dart';
import './step/listening_session_chrome_is_shown.dart';
import './step/i_open_the_share_link_in_while_signed_out.dart';
import './step/i_choose_the_translation.dart';

void main() {
  group('''Share a passage''', () {
    testWidgets('''Sharing the passage that is playing''', (tester) async {
      await thePassagePlayingIs(tester, '1 Cor 13:4-7');
      await iShareTheCurrentPassage(tester);
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=1+Cor+13:4-7');
      await theSharePayloadContains(tester, '1 Cor 13:4-7');
      await theSharePayloadDoesNotContainTheVerse(
          tester, 'Love is patient, love is kind');
    });
    testWidgets('''Sharing a passage from My Passages''', (tester) async {
      await iHaveInMyPassages(tester, '1 Cor 13:4-7');
      await iShareFromMyPassages(tester, '1 Cor 13:4-7');
      await theShareLinkContains(
          tester, 'https://selahword.web.app/?ref=1+Cor+13:4-7');
      await theSharePayloadContains(tester, '1 Cor 13:4-7');
      await theSharePayloadDoesNotContainTheVerse(
          tester, 'Love is patient, love is kind');
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
