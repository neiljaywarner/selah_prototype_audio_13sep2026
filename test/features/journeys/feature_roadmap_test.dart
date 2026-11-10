import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feature_voting_notifier.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feature_voting_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/presentation/widgets/feature_voting_sheet.dart';

import '../../support/fakes/recording_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openRoadmap(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = FeatureVotingService(
      dio: Dio()..httpClientAdapter = RecordingHttpAdapter(statusCode: 200, body: '{"documents":[]}'),
      prefs: prefs,
    );
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          featureVotingServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: Scaffold(body: FeatureVotingSheet())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('The roadmap is readable without an account', (tester) async {
    await openRoadmap(tester);
    expect(find.text('Feature Roadmap & Feedback'), findsOneWidget);
    expect(find.text('Verse & Word-Level Karaoke Timestamps'), findsOneWidget);
    expect(find.text('COMMUNITY FEATURE VOTING'), findsOneWidget);
    expect(find.textContaining('Sign in'), findsNothing);
  });

  testWidgets('Voting once records the listener\'s vote', (tester) async {
    await openRoadmap(tester);
    final title = find.text('Verse & Word-Level Karaoke Timestamps');
    expect(title, findsOneWidget);
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    final rect = tester.getRect(title);
    await tester.tapAt(rect.centerLeft - const Offset(28, 0));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(FeatureVotingSheet));
    final voted = ProviderScope.containerOf(context)
        .read(featureVotingProvider)
        .features
        .firstWhere((item) => item.id == 'karaoke_timestamps');
    expect(voted.hasVoted, isTrue);
    expect(voted.votes, 1);
    expect(find.text('1'), findsWidgets);
  });
}
