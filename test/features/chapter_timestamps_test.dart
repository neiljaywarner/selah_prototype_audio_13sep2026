import 'package:flutter_test/flutter_test.dart';

import 'step/i_open_the_share_link_in_while_signed_out.dart';
import 'step/the_next_timestamp_load_is_held.dart';
import 'step/i_load_the_bundled_chapter.dart';
import 'step/timestamp_loads_continue.dart';
import 'step/the_loaded_timestamps_start_at_verse.dart';

void main() {
  group('Chapter timestamps stay with the current load', () {
    testWidgets('An older chapter load keeps the newer timestamps', (tester) async {
      await iOpenTheShareLinkInWhileSignedOut(
          tester,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33',
          'BSB');
      await theNextTimestampLoadIsHeld(tester);
      await iLoadTheBundledChapter(tester, 'PSA', 62);
      await iLoadTheBundledChapter(tester, '1CO', 13);
      await timestampLoadsContinue(tester);
      await theLoadedTimestampsStartAtVerse(tester, 4);
    });
  });
}
