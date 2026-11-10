// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter_test/flutter_test.dart';

import './step/the_app_opens_from_the_android_link.dart';
import './step/i_see_the_passage.dart';
import './step/i_am_not_asked_to_sign_in.dart';
import './step/i_am_not_asked_to_read_aloud.dart';
import './step/read_aloud_did_not_start.dart';
import './step/the_app_is_open_signed_out.dart';
import './step/an_android_link_arrives.dart';
import './step/i_see_a_friendly_passage_error.dart';
import './step/playback_is_unavailable.dart';

void main() {
  group('''Open an Android App Link''', () {
    testWidgets('''A cold start opens the shared passage''', (tester) async {
      await theAppOpensFromTheAndroidLink(
          tester, 'https://selahword.web.app/?ref=1+Cor+13:4-7');
      await iSeeThePassage(tester, '1 Cor 13:4-7');
      await iAmNotAskedToSignIn(tester);
      await iAmNotAskedToReadAloud(tester);
      await readAloudDidNotStart(tester);
    });
    testWidgets('''A link while the app is open switches the passage''',
        (tester) async {
      await theAppIsOpenSignedOut(tester);
      await anAndroidLinkArrives(
          tester, 'https://selahword.web.app/?ref=Psalm+62:5-7');
      await iSeeThePassage(tester, 'Psalm 62:5-7');
      await iAmNotAskedToSignIn(tester);
      await iAmNotAskedToReadAloud(tester);
      await readAloudDidNotStart(tester);
    });
    testWidgets('''A bad Android link shows a friendly error''', (tester) async {
      await theAppOpensFromTheAndroidLink(
          tester, 'https://selahword.web.app/?ref=NotABook+99:1');
      await iSeeAFriendlyPassageError(tester);
      await playbackIsUnavailable(tester);
      await iAmNotAskedToReadAloud(tester);
      await readAloudDidNotStart(tester);
    });
  });
}
