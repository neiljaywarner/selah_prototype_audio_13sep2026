import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feedback_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/remote_config/remote_config_service.dart';

class MockAdapter implements HttpClientAdapter {
  late RequestOptions lastRequestOptions;
  late dynamic lastData;
  int statusCode = 201;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    lastData = options.data;
    return ResponseBody.fromString(
      '{"id": 1, "number": 1, "title": "Test Issue"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('GitHub Private Feedback Hub Integration Tests (njwandroid/selahfeedback)', () {
    late Dio testDio;
    late MockAdapter mockAdapter;

    setUp(() {
      mockAdapter = MockAdapter();
      testDio = Dio()..httpClientAdapter = mockAdapter;
    });

    test('submitGitHubIssueFeedback posts to private repo with Bearer token', () async {
      final success = await FeedbackService.submitGitHubIssueFeedback(
        title: '[User Report] Audio stream hiccup',
        body: 'Audio paused unexpectedly on 1 Cor 13:4',
        labels: ['user-feedback', 'bug', 'v0.3.1'],
        token: 'test_token_secret_123',
        dioClient: testDio,
      );

      expect(success, isTrue);
      expect(mockAdapter.lastRequestOptions.uri.toString(),
          'https://api.github.com/repos/njwandroid/selahfeedback/issues');
      expect(mockAdapter.lastRequestOptions.headers['Authorization'], 'Bearer test_token_secret_123');
      expect(mockAdapter.lastRequestOptions.headers['Accept'], 'application/vnd.github.v3+json');

      final payload = mockAdapter.lastData as Map<String, dynamic>;
      expect(payload['title'], '[User Report] Audio stream hiccup');
      expect(payload['body'], 'Audio paused unexpectedly on 1 Cor 13:4');
      expect(payload['labels'], ['user-feedback', 'bug', 'v0.3.1']);
    });

    test('submitBetterFeedback routes visual feedback and screenshot metadata to GitHub', () async {
      final feedback = UserFeedback(
        text: 'The text overlay is slightly obscured on dark backgrounds.',
        screenshot: Uint8List.fromList([1, 2, 3, 4, 5]),
      );

      await FeedbackService.submitBetterFeedback(
        feedback: feedback,
        rating: 3,
        face: 'neutral',
        email: 'tester@example.com',
        githubToken: 'gho_dummy_token',
        dioClient: testDio,
      );

      expect(mockAdapter.lastRequestOptions.uri.toString(),
          'https://api.github.com/repos/njwandroid/selahfeedback/issues');
      final payload = mockAdapter.lastData as Map<String, dynamic>;
      expect(payload['title'], contains('[Feedback] 😐 (3/5)'));
      expect(payload['body'], contains('The text overlay is slightly obscured'));
      expect(payload['body'], contains('tester@example.com'));
      expect(payload['body'], contains('Captured (5 bytes)'));
      expect(payload['labels'], contains('screenshot'));
      expect(payload['labels'], contains('neutral'));
    });

    test('SelahRemoteConfig parses and stores github_feedback_token securely', () {
      final config = SelahRemoteConfig.fromJson({
        'enable_topic_tabs': true,
        'github_feedback_token': 'gho_remote_config_token_abc',
      });

      expect(config.githubFeedbackToken, 'gho_remote_config_token_abc');
      expect(config.toJson()['github_feedback_token'], 'gho_remote_config_token_abc');

      final copied = config.copyWith(githubFeedbackToken: 'gho_new_token');
      expect(copied.githubFeedbackToken, 'gho_new_token');
    });
  });
}
