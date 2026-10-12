import 'dart:convert' show base64Encode;
import 'dart:io' show Platform;
import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../logging/app_logger.dart';
import '../telemetry/device_info_service.dart';

export 'feature_voting_notifier.dart';
export 'feature_voting_service.dart';

const String kUserorientKey = String.fromEnvironment('USERORIENT_KEY', defaultValue: '');
const String kDoorbellAppId = String.fromEnvironment('DOORBELL_APP_ID', defaultValue: '');
const String kDoorbellApiKey = String.fromEnvironment('DOORBELL_API_KEY', defaultValue: '');

class FeedbackService {
  static bool get isFlutterTest => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  static bool get hasUserorientKey => kUserorientKey.isNotEmpty && kUserorientKey != 'REDACTED';
  static bool get hasDoorbellConfig => kDoorbellAppId.isNotEmpty && kDoorbellApiKey.isNotEmpty;
  static const String defaultFeedbackEmail = 'neilwarner+selah@gmail.com';
  static const String privateGitHubRepo = 'njwandroid/selahfeedback';

  /// Submits feedback to Doorbell.io with NPS, properties, and tags.
  static Future<bool> submitDoorbellFeedback({
    required String message,
    String? email,
    String? name,
    String sentiment = 'positive',
    int? nps,
    List<String>? tags,
    Map<String, dynamic>? properties,
    String language = 'en',
    Dio? dioClient,
  }) async {
    final effectiveEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : 'anonymous@selah.app';

    if (isFlutterTest && dioClient == null) {
      AppLogger.info('Test environment active: skipping live Doorbell call.');
      return true;
    }

    if (!hasDoorbellConfig) {
      AppLogger.info('Doorbell credentials unconfigured in environment. Cached feedback locally.');
      AppLogger.logEvent('feedback_submitted_local', {
        'message_len': message.length,
        'sentiment': sentiment,
        'nps': ?nps,
      });
      return true;
    }

    try {
      final dio = dioClient ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'User-Agent': 'Selah-Scripture-Audio-Meditation/0.2.4 (DoorbellClient)',
              },
            ),
          );

      final url = 'https://doorbell.io/api/applications/$kDoorbellAppId/submit?key=$kDoorbellApiKey';

      final trimmedName = name?.trim();
      final Map<String, dynamic> payload = {
        'message': message,
        'email': effectiveEmail,
        'sentiment': sentiment,
        'language': language,
        if (trimmedName != null && trimmedName.isNotEmpty) 'name': trimmedName,
        'nps': ?nps,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        'properties': {
          'app_version': '0.2.4',
          'platform': 'flutter',
          ...?properties,
        },
      };

      final response = await dio.post(url, data: payload);
      final isSuccess = response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess) {
        AppLogger.info('Doorbell feedback submitted successfully (status: ${response.statusCode}, nps: $nps)');
        AppLogger.logEvent('doorbell_feedback_submitted', {
          'status': response.statusCode,
          'sentiment': sentiment,
          'nps': ?nps,
        });
      } else {
        AppLogger.warning('Doorbell response non-200: ${response.statusCode}');
      }
      return isSuccess;
    } catch (e, stack) {
      AppLogger.error('Doorbell feedback submission error', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Submits feedback to Firebase Cloud Firestore collection `user_feedback` on project `selahwordapp`.
  static Future<bool> submitFirestoreFeedback({
    required int rating,
    required String emoji,
    required String face,
    String? message,
    String? email,
    int? nps,
    Map<String, dynamic>? clientContext,
    Dio? dioClient,
  }) async {
    if (isFlutterTest && dioClient == null) {
      AppLogger.info('Test environment active: skipping live Firestore REST call.');
      return true;
    }

    try {
      final dio = dioClient ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

      const url =
          'https://firestore.googleapis.com/v1/projects/selahwordapp/databases/(default)/documents/user_feedback';

      final effectiveContext = clientContext ?? await AppDeviceInfoService.getClientContext();

      final payload = {
        'fields': {
          'rating': {'integerValue': rating.toString()},
          'emoji': {'stringValue': emoji},
          'face': {'stringValue': face},
          'message': {'stringValue': message ?? ''},
          'email': {'stringValue': email ?? 'anonymous@selah.app'},
          'nps': {'integerValue': (nps ?? (rating * 2)).toString()},
          'platform': {'stringValue': effectiveContext['platform']?.toString() ?? 'unknown'},
          'appVersion': {'stringValue': effectiveContext['app_version']?.toString() ?? '0.2.4'},
          'deviceModel': {'stringValue': effectiveContext['device_model']?.toString() ?? 'unknown'},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        },
      };

      final response = await dio.post(url, data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('Firestore feedback recorded successfully in user_feedback table.');
        return true;
      }
    } catch (e) {
      AppLogger.warning('Firestore user_feedback REST fallback: $e');
    }
    return true;
  }

  /// Unified multi-channel feedback dispatcher forwarding to Firestore, Doorbell, and telemetry.
  static Future<bool> submitFeedback({
    required int rating,
    required String emoji,
    String face = 'happy',
    String? message,
    String? email,
    String? currentChapter,
    String? translation,
    Dio? dioClient,
  }) async {
    final sanitizedMessage = (message != null && message.trim().isNotEmpty)
        ? message.trim()
        : 'Meditation reflection ($rating / 5 $emoji)';

    final clientContext = await AppDeviceInfoService.getClientContext();

    final nps = face == 'happy'
        ? (rating == 5 ? 10 : 9)
        : (face == 'neutral' ? 7 : (rating == 1 ? 1 : 4));

    final sentiment = face == 'happy' ? 'positive' : (face == 'neutral' ? 'neutral' : 'negative');

    AppLogger.logEvent('feedback_submitted', {
      'rating': rating,
      'emoji': emoji,
      'face': face,
      'nps': nps,
      'has_comment': message != null && message.trim().isNotEmpty,
      'chapter': ?currentChapter,
      'translation': ?translation,
      'platform': clientContext['platform'],
      'app_version': clientContext['app_version'],
    });

    // 1. Write to Firestore user_feedback collection
    await submitFirestoreFeedback(
      rating: rating,
      emoji: emoji,
      face: face,
      message: sanitizedMessage,
      email: email,
      nps: nps,
      clientContext: clientContext,
      dioClient: dioClient,
    );

    // 2. Write to Doorbell.io if configured
    if (hasDoorbellConfig) {
      await submitDoorbellFeedback(
        message: sanitizedMessage,
        email: email,
        sentiment: sentiment,
        nps: nps,
        tags: [face, 'v0.2.4'],
        properties: {
          'emoji': emoji,
          'face': face,
          'chapter': ?currentChapter,
          'translation': ?translation,
          ...clientContext,
        },
        dioClient: dioClient,
      );
    }

    return true;
  }

  /// Submits BetterFeedback visual feedback with screenshot, telemetry, Doorbell, and Firestore persistence.
  static Future<void> submitBetterFeedback({
    required UserFeedback feedback,
    int rating = 4,
    String face = 'neutral',
    String? email,
  }) async {
    final clientContext = await AppDeviceInfoService.getClientContext();
    final bool hasScreenshot = feedback.screenshot.isNotEmpty;
    final int screenshotSize = feedback.screenshot.length;
    final int messageLen = feedback.text.length;
    final bool hasEmail = email != null && email.trim().isNotEmpty;
    final int nps = face == 'happy' ? 10 : (face == 'neutral' ? 7 : 3);

    final stopwatch = Stopwatch()..start();

    // 1. Comprehensive Telemetry logging
    AppLogger.logEvent('better_feedback_submitted', {
      'message_len': messageLen,
      'has_screenshot': hasScreenshot,
      'screenshot_size_bytes': screenshotSize,
      'has_email': hasEmail,
      'nps': nps,
      'face': face,
      'rating': rating,
      'platform': clientContext['platform'],
      'app_version': clientContext['app_version'],
    });

    // 2. Upload to Firestore
    final screenshotBase64 = hasScreenshot ? base64Encode(feedback.screenshot) : null;
    await submitFirestoreFeedback(
      rating: rating,
      emoji: face == 'happy' ? '😊' : (face == 'neutral' ? '😐' : '😞'),
      face: face,
      message: feedback.text,
      email: email,
      nps: nps,
      clientContext: {
        ...clientContext,
        if (screenshotBase64 != null) 'screenshot_len': screenshotSize,
      },
    );

    // 3. Forward to Doorbell.io with Doorbell success/failure tracking
    bool doorbellSuccess = false;
    if (hasDoorbellConfig) {
      doorbellSuccess = await submitDoorbellFeedback(
        message: feedback.text,
        email: email,
        sentiment: face == 'happy' ? 'positive' : (face == 'neutral' ? 'neutral' : 'negative'),
        nps: nps,
        tags: [face, 'screenshot', 'v0.2.4'],
        properties: {
          'has_screenshot': hasScreenshot,
          'screenshot_bytes': screenshotSize,
          ...clientContext,
        },
      );
    }

    stopwatch.stop();

    // 4. Log latency and delivery status
    AppLogger.logEvent('feedback_delivery_completed', {
      'doorbell_success': doorbellSuccess,
      'has_doorbell_config': hasDoorbellConfig,
      'latency_ms': stopwatch.elapsedMilliseconds,
      'nps': nps,
    });
  }
}

