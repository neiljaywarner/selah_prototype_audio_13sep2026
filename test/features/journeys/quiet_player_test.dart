import 'package:flutter_test/flutter_test.dart';

import 'step/quiet_player_steps.dart';

void main() {
  group('Listening without an ESV key', () {
    testWidgets('The player opens on the featured passage and does not speak', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await iSeeTheSelahHeader(tester);
      await iSeeThePassageText(tester, 'Love is patient, love is kind');
      await speechHasNotStarted(tester);
      await iAmNotAskedToSignIn(tester);
    });

    testWidgets('An unknown reference does not replace the passage or start speech', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await iSearchFor(tester, 'NotABook 99');
      await iSeeThatTheReferenceWasRejected(tester);
      await iSeeThePassageText(tester, 'Love is patient, love is kind');
      await speechHasNotStarted(tester);
    });

    testWidgets('Settings lists the translations available without a key', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await iOpenMeditationSettings(tester);
      await iSeeText(tester, 'Meditation Settings');
      await iSeeText(tester, 'BIBLE TRANSLATION');
      await iSeeText(tester, 'BSB');
      await iSeeText(tester, 'WEB');
    });
  });
}
