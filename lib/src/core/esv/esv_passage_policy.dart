import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/meditation/domain/bible_translation.dart';
import '../constants/api_constants.dart';
import '../preferences/user_preferences.dart';
import 'esv_api_client.dart';

/// Compile-time gate for showing the in-app experimental narrator toggle.
const bool kEnableExperimentalApiBibleDevFlag = bool.fromEnvironment(
  'ENABLE_EXPERIMENTAL_API_BIBLE',
  defaultValue: true,
);

bool get isEsvApiConfigured => sanitizedEsvApiKey.isNotEmpty;

final esvApiClientProvider = Provider<EsvApiClient>((ref) => EsvApiClient());

/// Decides whether passages load from Crossway ESV or API.Bible narrators.
class EsvPassagePolicy {
  const EsvPassagePolicy({
    required this.esvConfigured,
    required this.experimentalApiBibleNarrator,
  });

  final bool esvConfigured;
  final bool experimentalApiBibleNarrator;

  /// ESV text + TTS for chips, catalog, and verse search.
  bool get useEsvForPassages => esvConfigured && !experimentalApiBibleNarrator;

  /// BSB / WEB / NIV picker and narrator routing.
  bool get showApiBibleTranslations => !esvConfigured || experimentalApiBibleNarrator;

  String get defaultTranslationCode => useEsvForPassages ? 'ESV' : BibleTranslation.fallback.code;

  List<BibleTranslation> get selectableTranslations {
    if (!showApiBibleTranslations) return const [BibleTranslation.esv];
    return BibleTranslation.values;
  }

  /// Normalizes UI titles (en dash) for ESV `q=` queries.
  static String normalizePassageQuery(String raw) =>
      raw.trim().replaceAll(RegExp(r'[–—]'), '-');
}

final experimentalApiBibleNarratorProvider = NotifierProvider<ExperimentalApiBibleNarratorNotifier, bool>(
  ExperimentalApiBibleNarratorNotifier.new,
);

class ExperimentalApiBibleNarratorNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(userPreferencesProvider).experimentalApiBibleNarrator;

  Future<void> setEnabled(bool enabled) async {
    await ref.read(userPreferencesProvider).setExperimentalApiBibleNarrator(enabled);
    state = enabled;
  }
}

final esvPassagePolicyProvider = Provider<EsvPassagePolicy>((ref) {
  final esvClient = ref.watch(esvApiClientProvider);
  final experimental = ref.watch(experimentalApiBibleNarratorProvider);
  return EsvPassagePolicy(
    esvConfigured: esvClient.isConfigured,
    experimentalApiBibleNarrator: experimental,
  );
});
