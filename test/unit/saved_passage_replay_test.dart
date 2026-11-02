import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_passage_policy.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/saved_passage.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/chapter_player_notifier.dart';
import '../support/fake_audio_players.dart';

/// Records every ESV `q=` and answers with one verse of text per call.
class _RecordingEsvAdapter implements HttpClientAdapter {
  final queries = <String>[];
  final textQueries = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = (options.queryParameters['q'] ?? '').toString();
    queries.add(query);
    if (options.path.contains('/passage/text/')) textQueries.add(query);
    final host = options.uri.host;
    if (host == 'audio.esv.org') {
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

  Future<void> expectReloadReplays(
    String typed,
    List<String> verseQueries,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final saved = await UserPreferences(prefs).saveMyPassage(
      SavedPassage(query: typed, label: typed),
    );
    expect(saved, SavePassageResult.saved);

    final adapter = _RecordingEsvAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.esv.org/v3'));
    dio.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        esvApiClientProvider.overrideWithValue(EsvApiClient(dio: dio, apiKey: 'test-esv-key')),
      ],
    );
    addTearDown(container.dispose);

    final stored = container.read(userPreferencesProvider).myPassages.single;
    expect(stored.query, PassageQuery.canonicalize(typed));
    await container.read(chapterPlayerProvider.notifier).tryPlayEsvPassage(stored.query);

    final state = container.read(chapterPlayerProvider);
    expect(
      adapter.textQueries,
      verseQueries,
      reason: 'reload must request each verse in "$typed", not the bare chapter',
    );
    expect(state.currentChapter.textContent, contains(verseQueries.first));
    expect(state.currentChapter.textContent, contains(verseQueries.last));
    expect(state.currentChapter.audioStreamUrl, contains(Uri.encodeComponent(stored.query)));
    expect(state.lastError, isNull);
  }

  test('reloading 1 Cor 13:4-7 replays that range on the ESV path', () async {
    await expectReloadReplays('1 Cor 13:4-7', const [
      '1 Cor 13:4',
      '1 Cor 13:5',
      '1 Cor 13:6',
      '1 Cor 13:7',
    ]);
  });

  test('a single verse reloads as that verse', () async {
    await expectReloadReplays('John 11:35', const ['John 11:35']);
  });

  test('a same-chapter range reloads as the range, not the whole chapter', () async {
    await expectReloadReplays('Psalm 23:1-3', const [
      'Psalm 23:1',
      'Psalm 23:2',
      'Psalm 23:3',
    ]);
  });
}
