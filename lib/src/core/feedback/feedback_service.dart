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
    String sentiment = 'positive',
  }) async {
    if (!hasDoorbellConfig) {
      AppLogger.info('Doorbell unconfigured. Logged feedback locally: $message');
      AppLogger.logEvent('feedback_submitted_local', {
        'message': message,
        'email': email,
        'sentiment': sentiment,
      });
      return true;
    }

    try {
      final dio = Dio();
      final url = 'https://doorbell.io/api/applications/$kDoorbellAppId/submit?key=$kDoorbellApiKey';
      final response = await dio.post(url, data: {
        'message': message,
        'email': email ?? 'anonymous@selah.app',
        'sentiment': sentiment,
        'properties': {
          'app_version': '0.2.0',
          'platform': 'flutter_web',
        },
      });
      AppLogger.info('Doorbell response status: ${response.statusCode}');
      AppLogger.logEvent('doorbell_feedback_submitted', {'status': response.statusCode});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      AppLogger.error('Doorbell submission failed', error: e, stackTrace: stack);
      return false;
    }
  }
}
