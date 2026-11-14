import 'share_passage_harness.dart';

/// Usage: ESV lookups are held
Future<void> esvLookupsAreHeld() async {
  SharePassageWorld.holdEsvLookups();
}
