import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/feedback/feedback_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/remote_config/remote_config_service.dart';

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
      '{"id": 1, "number": 1, "title": "Test Issue", "content": {"download_url": "https://raw.github.com/test", "html_url": "https://github.com/test"}}',
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
          'https://api.github.com/repos/neiljaywarner/selahprivatefeedback/issues');
      expect(mockAdapter.lastRequestOptions.headers['Authorization'], 'Bearer test_token_secret_123');
      expect(mockAdapter.lastRequestOptions.headers['Accept'], 'application/vnd.github.v3+json');

      final payload = mockAdapter.lastData as Map<String, dynamic>;
      expect(payload['title'], '[User Report] Audio stream hiccup');
      expect(payload['body'], 'Audio paused unexpectedly on 1 Cor 13:4');
      expect(payload['labels'], ['user-feedback', 'bug', 'v0.3.1']);
    });

    test('uploadScreenshotAsset uploads PNG bytes via GitHub Contents API', () async {
      final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
      final url = await FeedbackService.uploadScreenshotAsset(
        bytes: bytes,
        fileName: 'test_shot.png',
        token: 'test_token_secret_123',
        dioClient: testDio,
      );

      expect(url, contains('neiljaywarner/selahprivatefeedback/main/feedback_assets/test_shot.png'));
      expect(mockAdapter.lastRequestOptions.method, 'PUT');
      expect(mockAdapter.lastRequestOptions.uri.toString(),
          'https://api.github.com/repos/neiljaywarner/selahprivatefeedback/contents/feedback_assets/test_shot.png');
      final payload = mockAdapter.lastData as Map<String, dynamic>;
      expect(payload['branch'], 'main');
      expect(payload['content'], isNotEmpty);
      expect(payload['message'], contains('test_shot.png'));
    });

    test('submitFeedback dispatches issue to GitHub when token configured', () async {
      final success = await FeedbackService.submitFeedback(
        rating: 5,
        emoji: '😊',
        face: 'happy',
        message: 'The contemplative pacing is deeply uplifting.',
        email: 'believer@example.com',
        currentChapter: 'John 1',
        translation: 'BSB',
        githubToken: 'gho_token_123',
        dioClient: testDio,
      );

      expect(success, isTrue);
      final issueRequest = mockAdapter.requests.firstWhere(
        (r) => r.uri.toString().endsWith('/issues'),
      );
      expect(issueRequest.uri.toString(), 'https://api.github.com/repos/njwandroid/selahfeedback/issues');
      final issuePayload = mockAdapter.requestBodies[mockAdapter.requests.indexOf(issueRequest)] as Map<String, dynamic>;
      expect(issuePayload['title'], contains('[Feedback] 😊 (5/5)'));
      expect(issuePayload['body'], contains('The contemplative pacing is deeply uplifting.'));
      expect(issuePayload['body'], contains('Public IP'));
      expect(issuePayload['body'], contains('127.0.0.1'));
      expect(issuePayload['body'], contains('believer@example.com'));
    });

    test('submitBetterFeedback routes visual feedback, uploads screenshot, and embeds markdown', () async {
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

      // Verify that screenshot was uploaded via PUT
      final uploadRequest = mockAdapter.requests.firstWhere(
        (r) => r.method == 'PUT' && r.uri.toString().contains('feedback_assets'),
      );
      expect(uploadRequest, isNotNull);

      // Verify issue was created via POST with embedded link
      final issueRequest = mockAdapter.requests.firstWhere(
        (r) => r.method == 'POST' && r.uri.toString().endsWith('/issues'),
      );
      final payload = mockAdapter.requestBodies[mockAdapter.requests.indexOf(issueRequest)] as Map<String, dynamic>;
      expect(payload['title'], contains('[Feedback] 😐 (3/5)'));
      expect(payload['body'], contains('The text overlay is slightly obscured'));
      expect(payload['body'], contains('tester@example.com'));
      expect(payload['body'], contains('![User Feedback Screenshot]'));
      expect(payload['body'], contains('feedback_assets'));
      expect(payload['body'], contains('Public IP'));
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
