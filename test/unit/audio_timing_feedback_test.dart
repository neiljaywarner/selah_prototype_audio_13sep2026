import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feedback_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/karaoke/timestamp_loader.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

class MockAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<dynamic> requestBodies = [];
  int statusCode = 201;

  RequestOptions get lastRequestOptions => requests.last;
  dynamic get lastData => requestBodies.last;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    requestBodies.add(options.data);
    return ResponseBody.fromString(
      '{"id": 99, "number": 99, "title": "Test Issue"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('Passage Audio Timing & Alignment Feedback (Issue #95 / #119)', () {
    late Dio testDio;
    late MockAdapter mockAdapter;

    setUp(() {
      mockAdapter = MockAdapter();
      testDio = Dio()..httpClientAdapter = mockAdapter;
    });

    test('submitAudioTimingFeedback thumbs-up returns true without creating issue', () async {
      final success = await FeedbackService.submitAudioTimingFeedback(
        passageTitle: 'Psalm 23:1-3',
        translationCode: 'BSB',
        isThumbsUp: true,
        dioClient: testDio,
      );

      expect(success, isTrue);
      expect(mockAdapter.requests, isEmpty);
    });

    test('submitAudioTimingFeedback thumbs-down creates GitHub issue with audio-alignment label', () async {
      final success = await FeedbackService.submitAudioTimingFeedback(
        passageTitle: 'Psalm 23:1-3',
        translationCode: 'BSB',
        isThumbsUp: false,
        startedWrong: true,
        endedWrong: true,
        userNote: 'Verse 1 clipped first word',
        githubToken: 'MOCK_TEST_TOKEN',
        dioClient: testDio,
      );

      expect(success, isTrue);
      expect(mockAdapter.requests.length, 1);
      final req = mockAdapter.lastRequestOptions;
      expect(req.uri.toString(), 'https://api.github.com/repos/neiljaywarner/selahprivatefeedback/issues');
      final data = mockAdapter.lastData as Map;
      expect(data['title'], contains('[Audio Timing] 👎 Psalm 23:1-3 (BSB)'));
      expect(data['labels'], contains('audio-alignment'));
      expect(data['body'], contains('Verse 1 clipped first word'));
      expect(data['body'], contains('Timing Start'));
      expect(data['body'], contains('Timing End'));
    });

    test('submitAudioTimingFeedback with timestampsMissing creates calibration task issue', () async {
      final success = await FeedbackService.submitAudioTimingFeedback(
        passageTitle: 'John 3:16-17',
        translationCode: 'BSB',
        isThumbsUp: false,
        timestampsMissing: true,
        githubToken: 'MOCK_TEST_TOKEN',
        dioClient: testDio,
      );

      expect(success, isTrue);
      expect(mockAdapter.requests.length, 1);
      final data = mockAdapter.lastData as Map;
      expect(data['title'], contains('[Passage Alignment] 👎 John 3:16-17 (BSB)'));
      expect(data['body'], contains('Verse Alignment'));
      expect(data['body'], contains('Issue #95 / #119'));
    });

    test('requestPassageAlignment submits dedicated passage request issue', () async {
      final success = await FeedbackService.requestPassageAlignment(
        passage: 'Philippians 4:4-8',
        translationCode: 'WEB',
        userNote: 'Would love to meditate on peace passage',
        githubToken: 'MOCK_TEST_TOKEN',
        dioClient: testDio,
      );

      expect(success, isTrue);
      expect(mockAdapter.requests.length, 1);
      final data = mockAdapter.lastData as Map;
      expect(data['title'], contains('[Passage Request] 🙏 Philippians 4:4-8 (WEB)'));
      expect(data['labels'], contains('audio-alignment'));
      expect(data['labels'], contains('passage-request'));
      expect(data['body'], contains('Would love to meditate on peace passage'));
    });

    test('TimestampLoaderService.hasTimestampsFor returns correct availability', () {
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'PSA', chapterNumber: 23), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'ROM', chapterNumber: 8), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'MAT', chapterNumber: 11), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: '1CO', chapterNumber: 13), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'COL', chapterNumber: 1), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'JHN', chapterNumber: 3), isTrue);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'GEN', chapterNumber: 1), isFalse);
      expect(TimestampLoaderService.hasTimestampsFor(bookCode: 'REV', chapterNumber: 21), isFalse);
    });

    test('PassageExcerpt.customExcerpt computes accurate clip window', () {
      final excerpt = PassageExcerpt.customExcerpt(
        bookCode: 'PSA',
        chapterNumber: 23,
        startVerse: 1,
        endVerse: 2,
        displayTitle: 'Psalm 23:1-2',
      );

      expect(excerpt, isNotNull);
      expect(excerpt!.bookCode, 'PSA');
      expect(excerpt.startVerse, 1);
      expect(excerpt.endVerse, 2);

      const timestamps = [
        VerseTimestamp(verse: 1, text: 'Lord is shepherd', startMs: 0, endMs: 4100),
        VerseTimestamp(verse: 2, text: 'Green pastures', startMs: 4100, endMs: 9500),
        VerseTimestamp(verse: 3, text: 'Restores soul', startMs: 9500, endMs: 16000),
      ];

      final window = excerpt.clipWindow(timestamps);
      expect(window, isNotNull);
      expect(window!.start, Duration.zero);
      expect(window.end, const Duration(milliseconds: 9500));
    });
  });
}
