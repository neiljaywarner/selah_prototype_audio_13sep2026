import 'package:flutter_test/flutter_test.dart';

import 'step/i_open_the_share_link_in_while_signed_out.dart';
import 'step/an_older_audio_load_is_overtaken_by.dart';
import 'step/i_am_not_asked_to_read_aloud.dart';
import 'step/the_loaded_timestamps_start_at_verse.dart';

void main() {
  group('A stale audio load stays quiet', () {
    testWidgets('An older audio load does not ask to read the newer chapter',
        (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33',
          'BSB');
      await anOlderAudioLoadIsOvertakenBy(tester, '1CO', 13);
      await iAmNotAskedToReadAloud(tester);
      await theLoadedTimestampsStartAtVerse(tester, 4);
    });
  });
}
