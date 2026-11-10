import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/remote_config/remote_config_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/audio_mode.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/chapter_picker_dialog.dart';

import 'step/quiet_player_steps.dart';
import '../../support/player_platform.dart';

void main() {
  group('Choosing a passage without an ESV key', () {
    testWidgets('typing Jn offers John and Jonah and does not start speech', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await tester.enterText(find.byType(TextField), 'Jn');
      await tester.pump();

      expect(find.text('John 1'), findsWidgets);
      expect(find.text('Jonah 1'), findsWidgets);
      await speechHasNotStarted(tester);
    });

    testWidgets('Psalm 23 uses the bundled narrator and does not speak', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await tester.enterText(find.byType(TextField), 'Psalm 23');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await flushPlayback(tester);

      expect(find.textContaining('Psalm 23'), findsWidgets);
      final state = _playerState(tester);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.currentChapter.audioStreamUrl, contains('PSA_23.mp3'));
      await textToSpeechHasNotSpoken(tester);
    });

    testWidgets('an unaligned range can be requested and the passage stays put', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await iSearchFor(tester, 'revelation 21:1-4');

      expect(find.text('Verse Timing Unaligned'), findsOneWidget);
      expect(find.text('Request Passage from Devs'), findsOneWidget);
      await tester.tap(find.text('Request Passage from Devs'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.textContaining('notified the devs'), findsOneWidget);
      expect(find.textContaining('Love is patient'), findsWidgets);
      await speechHasNotStarted(tester);
    });

    testWidgets('the play control loads the bundled narrator and does not speak', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await flushPlayback(tester);

      final state = _playerState(tester);
      expect(state.audioMode, AudioMode.narrator);
      expect(state.currentChapter.audioStreamUrl, contains('1CO_13.mp3'));
      await textToSpeechHasNotSpoken(tester);
    });

    testWidgets('the speed control changes pace without starting speech', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      expect(find.text('1.0x'), findsOneWidget);
      await tester.tap(find.text('1.0x'));
      await tester.pump();
      expect(find.text('1.1x'), findsOneWidget);
      expect(_playerState(tester).playbackSpeed, 1.1);
      await speechHasNotStarted(tester);
    });

    testWidgets('the book browser can be closed without loading a chapter', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await tester.tap(find.byTooltip('Browse All 66 Books'));
      await tester.pumpAndSettle();

      expect(find.text('Browse 66 Books & Chapters'), findsOneWidget);
      await tester.tap(find.text('New Testament (27)'));
      await tester.pumpAndSettle();
      expect(find.text('Matthew'), findsWidgets);
      expect(find.text('Genesis'), findsNothing);

      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      expect(find.text('Browse 66 Books & Chapters'), findsNothing);
      expect(find.textContaining('Love is patient'), findsWidgets);
      await speechHasNotStarted(tester);
    });

    testWidgets('the book browser selects Psalms 23 without speaking', (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      String? code;
      var chapter = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterPickerDialog(
              onChapterSelected: (bookCode, chapterNumber, _) {
                code = bookCode;
                chapter = chapterNumber;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Psalms');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Psalms'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Psalms selected'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('23'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('23'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Psalms 23'));
      await tester.pumpAndSettle();

      expect(code, 'PSA');
      expect(chapter, 23);
    });

    testWidgets('a quiet-hour banner and Peace topic do not start speech', (tester) async {
      await _openQuietHour(tester);
      expect(find.text('A quiet hour for the evening'), findsOneWidget);
      expect(find.textContaining('Peace'), findsWidgets);
      await tester.tap(find.textContaining('Peace'));
      await tester.pumpAndSettle();
      expect(find.text('Philippians 4'), findsWidgets);
      _expectNoSpeech(tester);
    });

    testWidgets('the sleep timer and tested passages stay silent until play', (tester) async {
      await thePlayerIsOpenWithoutAnEsvKey(tester);
      await tester.tap(find.byIcon(Icons.bedtime_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Tranquil Sleep Timer'), findsOneWidget);
      await tester.tap(find.text('15 min'));
      await tester.pumpAndSettle();
      expect(_playerState(tester).sleepTimerMinutes, 15);
      expect(find.text('15m'), findsOneWidget);

      final more = find.text('+ More (12)');
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.textContaining('Curated'), findsWidgets);
      final cohort = find.textContaining('The 77');
      await tester.ensureVisible(cohort);
      await tester.tap(cohort);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Request Another Passage'));
      await tester.pumpAndSettle();
      expect(find.text('Verse Timing Unaligned'), findsOneWidget);
      await speechHasNotStarted(tester);
    });
  });
}

Future<void> flushPlayback(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _QuietHourConfig extends RemoteConfigNotifier {
  @override
  SelahRemoteConfig build() {
    return const SelahRemoteConfig(
      enableTopicTabs: true,
      announcementBannerText: 'A quiet hour for the evening',
      featureVotingEnabled: true,
    );
  }
}

Future<void> _openQuietHour(WidgetTester tester) async {
  _screenTtsCalls.clear();
  installSelahPlayerPlatform(ttsCalls: _screenTtsCalls);
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [remoteConfigProvider.overrideWith(_QuietHourConfig.new)],
      child: const MaterialApp(home: ChapterPlayerScreen()),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void _expectNoSpeech(WidgetTester tester) {
  expect(_playerState(tester).isPlaying, isFalse);
  expect(_screenTtsCalls.where((call) => call.method == 'speak'), isEmpty);
}

final _screenTtsCalls = <MethodCall>[];

ChapterPlayerState _playerState(WidgetTester tester) {
  final context = tester.element(find.byType(ChapterPlayerScreen));
  return ProviderScope.containerOf(context).read(chapterPlayerProvider);
}
