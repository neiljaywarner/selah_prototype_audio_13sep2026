import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/remote_config/remote_config_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/passage_share_launcher.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures the message the share button would hand to the platform.
///
/// The Android share sheet is covered by `.maestro/share_passage_android.yaml`.
/// This recorder keeps the device test on the payload: reference, URL, and
/// short attribution, never the verse body.
class _RecordingLauncher implements PassageShareLauncher {
  PassageSharePayload? last;

  @override
  Future<void> share(PassageSharePayload payload) async {
    last = payload;
  }
}

class _QuietRemoteConfig extends RemoteConfigNotifier {
  @override
  SelahRemoteConfig build() => const SelahRemoteConfig();
}

const _validShareUrl =
    'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=1+Cor+13:4-7';
const _brokenShareUrl =
    'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=NotABook+99:1';

void main() {
  patrolTest(
    'a signed-out share link lands on 1 Cor 13:4-7 and playback can start',
    ($) async {
      await _pump($, initialShareUrl: _validShareUrl);

      expect($('SELAH'), findsOneWidget);
      expect($(RegExp('1 Cor 13:4-7')), findsWidgets);
      expect($(RegExp('Sign in')), findsNothing);
      expect($(RegExp("Couldn't open that link")), findsNothing);

      final landed = _playerState($);
      expect(landed.currentChapter.bookCode, '1CO');
      expect(landed.currentChapter.chapterNumber, 13);
      expect(
        PassageShareLink.tryParse(landed.currentChapter.reference)?.canonical,
        '1 Cor 13:4-7',
      );
      expect(landed.lastError, isNull);

      await $(#play_passage_button).scrollTo();
      await $(#play_passage_button).tap();
      await Future<void>.delayed(const Duration(seconds: 2));

      final playing = _playerState($);
      expect(playing.currentChapter.bookCode, '1CO');
      expect(
        playing.isPlaying ||
            playing.isLoading ||
            playing.currentChapter.audioStreamUrl.isNotEmpty,
        isTrue,
        reason:
            'playing=${playing.isPlaying} loading=${playing.isLoading} '
            'url=${playing.currentChapter.audioStreamUrl} error=${playing.lastError}',
      );
      expect(
        (playing.lastError ?? '').toLowerCase().contains('sign in'),
        isFalse,
      );
      expect(
        (playing.lastError ?? '').toLowerCase().contains('log in'),
        isFalse,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  patrolTest(
    'a broken share link stays on the player and shows a friendly error',
    ($) async {
      await _pump($, initialShareUrl: _brokenShareUrl);

      expect($('SELAH'), findsOneWidget);
      expect($(RegExp("Couldn't open that link")), findsOneWidget);
      expect($(RegExp('NotABook 99:1')), findsWidgets);
      expect($(RegExp('not a Bible passage')), findsWidgets);
      expect($(RegExp('does not open a passage')), findsOneWidget);
      expect($(RegExp('Love is patient')), findsNothing);
      expect($(RegExp('Sign in')), findsNothing);
      expect($(#current_passage_reference), findsOneWidget);

      final rejected = _playerState($);
      expect(rejected.currentChapter.bookCode, isEmpty);
      expect(rejected.lastError, contains('NotABook 99:1'));
      expect(rejected.lastError, contains("Couldn't open that link"));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  patrolTest(
    'sharing from the player and from My Passages sends the reference only',
    ($) async {
      final launcher = await _pump($, saved: const ['1 Cor 13:4-7']);
      final attribution = _playerState($).translation.shortAttribution;

      expect($(RegExp(r'1 Cor 13:4')), findsWidgets);
      await $(#share_current_passage).scrollTo();
      await $(#share_current_passage).tap();
      await $.pump(const Duration(milliseconds: 300));

      _expectReferenceOnly(launcher.last, attribution);
      expect($(RegExp('Link ready to share: 1 Cor 13:4-7')), findsOneWidget);

      await $(#open_my_passages).scrollTo();
      await $(#open_my_passages).tap();
      await $.pump(const Duration(milliseconds: 400));
      expect($(#my_passages_sheet), findsOneWidget);
      expect($(RegExp('without an account')), findsOneWidget);

      await $(const Key('share_my_passage_1 Cor 13:4-7')).tap();
      await $.pump(const Duration(milliseconds: 300));
      _expectReferenceOnly(launcher.last, attribution);
      expect($(RegExp('Link ready to share: 1 Cor 13:4-7')), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

ChapterPlayerState _playerState(PatrolIntegrationTester $) {
  final element = $.tester.element(find.byType(ChapterPlayerScreen));
  return ProviderScope.containerOf(element).read(chapterPlayerProvider);
}

void _expectReferenceOnly(PassageSharePayload? payload, String attribution) {
  expect(payload, isNotNull);
  final shared = payload!;
  expect(shared.reference, '1 Cor 13:4-7');
  expect(shared.url, contains('?ref=1+Cor+13:4-7'));
  expect(
    shared.url,
    startsWith(
      'https://selahword.web.app/',
    ),
  );
  expect(shared.attribution, attribution);
  expect(shared.message, contains(shared.reference));
  expect(shared.message, contains(shared.url));
  expect(shared.message, contains(attribution));
  expect(shared.message.toLowerCase(), isNot(contains('love is patient')));
  expect(shared.message.toLowerCase(), isNot(contains('love is kind')));
}

Future<_RecordingLauncher> _pump(
  PatrolIntegrationTester $, {
  String? initialShareUrl,
  List<String> saved = const [],
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (saved.isNotEmpty) {
    await prefs.setStringList(UserPreferences.savedChaptersKey, saved);
  }
  final launcher = _RecordingLauncher();
  await $.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        passageShareLauncherProvider.overrideWithValue(launcher),
        remoteConfigProvider.overrideWith(_QuietRemoteConfig.new),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ChapterPlayerScreen(
          initialShareUrl: initialShareUrl,
          readPlatformLink: false,
        ),
      ),
    ),
  );
  // The link is applied on the first frame after initState.
  await $.pump(const Duration(milliseconds: 400));
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return launcher;
}
