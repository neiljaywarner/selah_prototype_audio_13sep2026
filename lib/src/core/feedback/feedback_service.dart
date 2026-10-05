import 'package:dio/dio.dart';
import '../logging/app_logger.dart';

const String kUserorientKey = String.fromEnvironment('USERORIENT_KEY', defaultValue: '');
const String kDoorbellAppId = String.fromEnvironment('DOORBELL_APP_ID', defaultValue: '');
const String kDoorbellApiKey = String.fromEnvironment('DOORBELL_API_KEY', defaultValue: '');

class RoadmapFeatureItem {
  final String id;
  final String title;
  final String description;
  final String targetVersion;
  int votes;
  bool hasVoted;

  RoadmapFeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.targetVersion,
    this.votes = 0,
    this.hasVoted = false,
  });
}

class FeedbackService {
  static final List<RoadmapFeatureItem> defaultRoadmapFeatures = [
    RoadmapFeatureItem(
      id: 'karaoke_timestamps',
      title: 'Verse & Word-Level Karaoke Timestamps',
      description:
          'Synchronized millisecond word highlighting with narrator audio using Faith Comes By Hearing BibleBrain alignment.',
      targetVersion: 'v0.3',
      votes: 42,
    ),
    RoadmapFeatureItem(
      id: 'gemini_voice_memorization',
      title: 'Voice Scripture Memorization Check (Gemini AI)',
      description:
          'Listen to user recite verses out loud with gentle pauses, checking accuracy and recitation progress.',
      targetVersion: 'v0.3.5',
      votes: 38,
    ),
    RoadmapFeatureItem(
      id: 'ambient_soundscapes',
      title: 'Layered Ambient Soundscapes',
      description:
          'Background nature audio (gentle rain, temple pads, morning birds) layered softly beneath scripture narration.',
      targetVersion: 'v0.4',
      votes: 29,
    ),
    RoadmapFeatureItem(
      id: 'audio_speed_controls',
      title: 'Paced Meditation Speeds (0.75x - 1.25x)',
      description:
          'Slow down audio for deep lectio divina contemplation or speed up for faster listening sessions.',
      targetVersion: 'v0.2.2',
      votes: 19,
    ),
  ];

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

  static void castVote(RoadmapFeatureItem item) {
    if (item.hasVoted) {
      item.votes--;
      item.hasVoted = false;
      AppLogger.logEvent('unvote_feature', {'feature_id': item.id});
    } else {
      item.votes++;
      item.hasVoted = true;
      AppLogger.logEvent('vote_feature', {'feature_id': item.id, 'new_total': item.votes});
    }
  }
}
