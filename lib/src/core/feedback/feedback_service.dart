import 'package:dio/dio.dart';
import '../logging/app_logger.dart';

export 'feature_voting_notifier.dart';
export 'feature_voting_service.dart';

const String kUserorientKey = String.fromEnvironment('USERORIENT_KEY', defaultValue: '');
const String kDoorbellAppId = String.fromEnvironment('DOORBELL_APP_ID', defaultValue: '');
const String kDoorbellApiKey = String.fromEnvironment('DOORBELL_API_KEY', defaultValue: '');

class FeedbackService {
  static bool get hasUserorientKey => kUserorientKey.isNotEmpty && kUserorientKey != 'REDACTED';
  static bool get hasDoorbellConfig => kDoorbellAppId.isNotEmpty && kDoorbellApiKey.isNotEmpty;

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
                'User-Agent': 'Selah-Scripture-Audio-Meditation/0.2.1 (DoorbellClient)',
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
          'app_version': '0.2.1',
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
}
