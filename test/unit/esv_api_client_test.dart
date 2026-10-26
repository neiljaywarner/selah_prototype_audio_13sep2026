import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/constants/api_constants.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';

void main() {
  test('1 Cor 13:4-7 expands to four single-verse queries', () {
    expect(EsvApiClient.expandToSingleVerses('1 Cor 13:4-7'), [
      '1 Cor 13:4',
      '1 Cor 13:5',
      '1 Cor 13:6',
      '1 Cor 13:7',
    ]);
  });

  test('en dash and spaces still expand verse by verse', () {
    expect(EsvApiClient.expandToSingleVerses('1 Cor 13:4 – 7'), [
      '1 Cor 13:4',
      '1 Cor 13:5',
      '1 Cor 13:6',
      '1 Cor 13:7',
    ]);
  });

  test('single verse stays a single query', () {
    expect(EsvApiClient.expandToSingleVerses('1 Cor 13:4'), ['1 Cor 13:4']);
  });

  test('a range over the per-minute cap is not exploded into calls', () {
    expect(EsvApiClient.expandToSingleVerses('1 Cor 13:1-61'), [
      '1 Cor 13:1-61',
    ]);
  });

  test('joined reference keeps the start and the last verse number', () {
    expect(
      EsvApiClient.joinedReference(const [
        EsvVerse(reference: '1 Corinthians 13:4', text: 'a'),
        EsvVerse(reference: '1 Corinthians 13:7', text: 'd'),
      ]),
      '1 Corinthians 13:4–7',
    );
  });

  test('placeholder and empty keys are not configured, and shell quotes are stripped', () {
    expect(sanitizeEnvSecret('REDACTED'), '');
    expect(sanitizeEnvSecret("'REDACTED'"), '');
    expect(sanitizeEnvSecret('"REDACTED"'), '');
    expect(sanitizeEnvSecret("'clean-token-123'"), 'clean-token-123');
    expect(sanitizeEnvSecret(' "clean-token-456" '), 'clean-token-456');

    expect(EsvApiClient(apiKey: 'REDACTED').isConfigured, isFalse);
    expect(EsvApiClient(apiKey: "'REDACTED'").isConfigured, isFalse);
    expect(EsvApiClient(apiKey: '').isConfigured, isFalse);

    final quotedClient = EsvApiClient(apiKey: "'present-token'");
    expect(quotedClient.isConfigured, isTrue);
    expect(quotedClient.apiKey, 'present-token');
  });

  test('directHwAudioUrl builds headerless Crossway CDN MP3 URLs for Web <audio>', () {
    expect(
      EsvApiClient.directHwAudioUrl('1 Cor 13:4–7'),
      'https://audio.esv.org/hw/1%20Cor%2013%3A4-7.mp3',
    );
    expect(
      EsvApiClient.directHwAudioUrl('1 Peter 5:7–9'),
      'https://audio.esv.org/hw/1%20Peter%205%3A7-9.mp3',
    );
    expect(
      EsvApiClient.directHwAudioUrl('John 11:35'),
      'https://audio.esv.org/hw/John%2011%3A35.mp3',
    );
  });

  test('resolvePassageAudioUrl on Web skips XHR redirect and returns directHwAudioUrl', () async {
    final adapter = _ScriptedEsvAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.esv.org/v3'));
    dio.httpClientAdapter = adapter;
    final client = EsvApiClient(dio: dio, apiKey: "'test-key'");

    final url = await client.resolvePassageAudioUrl('1 Cor 13:4–7', isWeb: true);
    expect(url, 'https://audio.esv.org/hw/1%20Cor%2013%3A4-7.mp3');
    expect(adapter.queries, isEmpty, reason: 'Web must not trigger CORS-blocked audio XHR');
  });

  test('resolvePassageAudioUrl on Native falls back to directHwAudioUrl if redirect header missing', () async {
    final adapter = _ScriptedEsvAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.esv.org/v3'));
    dio.httpClientAdapter = adapter;
    final client = EsvApiClient(dio: dio, apiKey: 'test-key');

    final url = await client.resolvePassageAudioUrl('1 Peter 5:7–9', isWeb: false);
    expect(url, 'https://audio.esv.org/hw/1%20Peter%205%3A7-9.mp3');
  });

  test('1 Cor 13:4-7 performs one HTTP call per verse', () async {
    final adapter = _ScriptedEsvAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.esv.org/v3'));
    dio.httpClientAdapter = adapter;
    final client = EsvApiClient(dio: dio, apiKey: 'test-key');

    final verses = await client.fetchVerseByVerse('1 Cor 13:4-7');

    expect(adapter.queries, [
      '1 Cor 13:4',
      '1 Cor 13:5',
      '1 Cor 13:6',
      '1 Cor 13:7',
    ]);
    expect(adapter.authorizations, everyElement('Token test-key'));
    expect(verses.map((verse) => verse.text).toList(), [
      'Love is patient.',
      'It does not envy.',
      'It does not rejoice at wrongdoing.',
      'Love bears all things.',
    ]);
    expect(EsvApiClient.joinedReference(verses), '1 Corinthians 13:4–7');
  });

  test('a missing verse aborts the range instead of skipping it', () async {
    final adapter = _ScriptedEsvAdapter(failQuery: '1 Cor 13:6');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.esv.org/v3'));
    dio.httpClientAdapter = adapter;
    final client = EsvApiClient(dio: dio, apiKey: 'test-key');

    final verses = await client.fetchVerseByVerse('1 Cor 13:4-7');

    expect(verses, isEmpty);
    expect(adapter.queries, ['1 Cor 13:4', '1 Cor 13:5', '1 Cor 13:6']);
  });
}

class _ScriptedEsvAdapter implements HttpClientAdapter {
  _ScriptedEsvAdapter({this.failQuery});

  final String? failQuery;
  final queries = <String>[];
  final authorizations = <String>[];

  static const _texts = <String, String>{
    '1 Cor 13:4': 'Love is patient.',
    '1 Cor 13:5': 'It does not envy.',
    '1 Cor 13:6': 'It does not rejoice at wrongdoing.',
    '1 Cor 13:7': 'Love bears all things.',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = options.queryParameters['q'] as String;
    queries.add(query);
    authorizations.add('${options.headers['Authorization']}');
    expect(options.queryParameters['include-verse-numbers'], isFalse);
    expect(options.queryParameters['include-headings'], isFalse);
    expect(options.queryParameters['include-footnotes'], isFalse);
    expect(options.queryParameters['include-passage-references'], isFalse);
    expect(options.queryParameters['include-short-copyright'], isFalse);

    final Map<String, dynamic> payload;
    if (query == failQuery) {
      payload = {'canonical': query, 'passages': <String>[]};
    } else {
      final verse = query.split(':').last;
      payload = {
        'canonical': '1 Corinthians 13:$verse',
        'passages': <String>['${_texts[query]}\n\n'],
      };
    }
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
