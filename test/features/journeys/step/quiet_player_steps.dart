import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/chapter_player_screen.dart';

import '../../../support/player_platform.dart';

final _ttsCalls = <MethodCall>[];

Future<void> thePlayerIsOpenWithoutAnEsvKey(WidgetTester tester) async {
  _ttsCalls.clear();
  installSelahPlayerPlatform(ttsCalls: _ttsCalls);
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: ChapterPlayerScreen()),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  expect(EsvApiClient().isConfigured, isFalse);
}

Future<void> iSeeTheSelahHeader(WidgetTester tester) async {
  expect(find.text('SELAH'), findsOneWidget);
}

Future<void> iSeeThePassageText(WidgetTester tester, String text) async {
  expect(find.textContaining(text, findRichText: true), findsWidgets);
}

Future<void> speechHasNotStarted(WidgetTester tester) async {
  final context = tester.element(find.byType(ChapterPlayerScreen));
  final playing = ProviderScope.containerOf(context).read(chapterPlayerProvider).isPlaying;
  expect(playing, isFalse, reason: 'TTS and the narrator must wait for the listener');
  expect(
    _ttsCalls.where((call) => call.method == 'speak'),
    isEmpty,
    reason: 'flutter_tts speak was invoked',
  );
}

Future<void> textToSpeechHasNotSpoken(WidgetTester tester) async {
  expect(
    _ttsCalls.where((call) => call.method == 'speak'),
    isEmpty,
    reason: 'flutter_tts speak was invoked',
  );
}

Future<void> iAmNotAskedToSignIn(WidgetTester tester) async {
  expect(find.textContaining('Sign in'), findsNothing);
  expect(find.textContaining('Create account'), findsNothing);
}

Future<void> iSearchFor(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> iSeeThatTheReferenceWasRejected(WidgetTester tester) async {
  expect(find.textContaining('only has'), findsOneWidget);
}

Future<void> iOpenMeditationSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> iSeeText(WidgetTester tester, String text) async {
  expect(find.text(text), findsWidgets);
}
