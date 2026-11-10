import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feedback_service.dart';

import '../support/fakes/recording_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a reflection with a token is filed, and a rejected upload is not called success', () async {
    final adapter = RecordingHttpAdapter(
      statusCode: 201,
      body: '{"id": 7, "number": 7, "title": "Reflection"}',
    );
    final dio = Dio()..httpClientAdapter = adapter;

    final filed = await FeedbackService.submitFeedback(
      rating: 5,
      emoji: '🙏',
      face: 'happy',
      message: 'The silence between readings gave me room to pray.',
      email: 'listener@example.com',
      currentChapter: 'Psalm 23',
      translation: 'BSB',
      githubToken: 'gho_test_token',
      dioClient: dio,
    );

    expect(filed, isTrue);
    expect(adapter.requests, isNotEmpty);
    final issue = adapter.requestBodies.whereType<Map>().lastWhere((body) => body.containsKey('title'));
    expect(issue['title'], contains('Feedback'));
    expect(issue['body'], contains('room to pray'));
    expect(issue['body'], contains('Psalm 23'));
    expect(issue['body'], contains('listener@example.com'));

    adapter.statusCode = 500;
    adapter.body = '{}';
    final rejected = await FeedbackService.submitGitHubIssueFeedback(
      title: 'clip',
      body: 'started late',
      token: 'gho_test_token',
      dioClient: dio,
    );
    expect(rejected, isFalse);
  });

  test('a screenshot note is attached when the upload is accepted', () async {
    final adapter = RecordingHttpAdapter(
      statusCode: 201,
      body: '{"content":{"download_url":"https://example.test/shot.png"}}',
    );
    final dio = Dio()..httpClientAdapter = adapter;

    await FeedbackService.submitBetterFeedback(
      feedback: UserFeedback(
        text: 'The verse highlight lagged the narrator by a breath.',
        screenshot: Uint8List.fromList([1, 2, 3, 4]),
      ),
      rating: 3,
      face: 'neutral',
      email: 'listener@example.com',
      githubToken: 'gho_test_token',
      dioClient: dio,
    );

    expect(adapter.requests.length, greaterThanOrEqualTo(2));
    expect(
      adapter.requests.any((request) => request.method == 'PUT'),
      isTrue,
      reason: 'the screenshot is uploaded before the issue is filed',
    );
  });

  test('a transport error is reported as a failed issue, not a silent success', () async {
    final adapter = RecordingHttpAdapter(
      error: DioException(
        requestOptions: RequestOptions(path: '/issues'),
        type: DioExceptionType.connectionError,
        message: 'offline',
      ),
    );
    final ok = await FeedbackService.submitGitHubIssueFeedback(
      title: 'offline',
      body: 'no network',
      token: 'gho_test_token',
      dioClient: Dio()..httpClientAdapter = adapter,
    );
    expect(ok, isFalse);
  });
}
