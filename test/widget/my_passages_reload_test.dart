import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/app.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import '../support/fake_audio_players.dart';

class _RecordingEsvAdapter implements HttpClientAdapter {
  final queries = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = (options.queryParameters['q'] ?? '').toString();
    queries.add(query);
    if (options.uri.host == 'audio.esv.org') {
      return ResponseBody.fromString('', 200);
    }
    if (options.path.contains('/passage/audio/')) {
      return ResponseBody.fromString(
        '',
        302,
        headers: {
          'location': ['https://audio.esv.org/hw/${Uri.encodeComponent(query)}.mp3'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'canonical': query,
        'passages': <String>['Text of $query.'],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeAudioPlayers);

  Future<ProviderContainer> pumpSelah(
    WidgetTester tester,
    SharedPreferences prefs,
    EsvApiClient client,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          esvApiClientProvider.overrideWithValue(client),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const SelahApp();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('type 1 Cor 13:4-7, save, reload, tap, and the ESV range plays', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final adapter = _RecordingEsvAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.esv.org/v3'));
    dio.httpClientAdapter = adapter;
    final client = EsvApiClient(dio: dio, apiKey: 'test-esv-key');

    await pumpSelah(tester, prefs, client);

    await tester.enterText(find.byType(TextField), '1 Cor 13:4-7');
    await tester.tap(find.byKey(const Key('save_my_passage_button')));
    await tester.pumpAndSettle();

    expect(find.text('Saved "1 Cor 13:4-7" to My passages'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-passage-1 Cor 13:4-7')), findsOneWidget);
    expect(
      UserPreferences(prefs).myPassages.single.query,
      '1 Cor 13:4-7',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    adapter.queries.clear();

    await pumpSelah(tester, prefs, client);
    expect(find.byKey(const ValueKey('my-passage-1 Cor 13:4-7')), findsOneWidget);

    final chip = find.byKey(const ValueKey('my-passage-1 Cor 13:4-7'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await _pumpUntil(tester, () => adapter.queries.contains('1 Cor 13:7'));

    const verses = ['1 Cor 13:4', '1 Cor 13:5', '1 Cor 13:6', '1 Cor 13:7'];
    expect(adapter.queries.where(verses.contains).toList(), verses);
    expect(adapter.queries.where((q) => q == '1 Cor 13' || q == '1 Corinthians 13'), isEmpty);
  });

  testWidgets('a saved single verse survives reload and is not replayed as a chapter', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final adapter = _RecordingEsvAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.esv.org/v3'));
    dio.httpClientAdapter = adapter;
    final client = EsvApiClient(dio: dio, apiKey: 'test-esv-key');

    await pumpSelah(tester, prefs, client);
    await tester.enterText(find.byType(TextField), 'John 11:35');
    await tester.tap(find.byKey(const Key('save_my_passage_button')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    adapter.queries.clear();

    await pumpSelah(tester, prefs, client);
    await tester.tap(find.byKey(const ValueKey('my-passage-John 11:35')));
    await _pumpUntil(tester, () => adapter.queries.contains('John 11:35'));

    expect(adapter.queries, contains('John 11:35'));
    expect(adapter.queries.where((q) => q == 'John 11'), isEmpty);
    expect(UserPreferences(prefs).myPassages.single.query, 'John 11:35');
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  String Function()? reason,
}) async {
  for (var i = 0; i < 40; i++) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(done(), isTrue, reason: reason?.call() ?? 'timed out waiting for replay');
}
