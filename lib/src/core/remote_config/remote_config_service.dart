import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

const String kFirestoreProjectId =
    String.fromEnvironment('FIRESTORE_PROJECT_ID', defaultValue: 'selahwordapp');
const bool kEnableTopicTabsEnv =
    bool.fromEnvironment('ENABLE_TOPIC_TABS', defaultValue: false);

/// Immutable data model containing resolved Selah remote configuration values.
class SelahRemoteConfig {
  final bool enableTopicTabs;
  final int silenceGapSeconds;
  final String defaultTranslation;
  final String announcementBannerText;
  final String feedbackEmailRecipient;
  final bool enableEmojiFeedback;
  final bool feedbackBoardEnabled;
  final bool featureVotingEnabled;

  const SelahRemoteConfig({
    this.enableTopicTabs = kEnableTopicTabsEnv,
    this.silenceGapSeconds = 4,
    this.defaultTranslation = 'BSB',
    this.announcementBannerText = '',
    this.feedbackEmailRecipient = 'neilwarner+selah@gmail.com',
    this.enableEmojiFeedback = true,
    this.feedbackBoardEnabled = true,
    this.featureVotingEnabled = false,
  });

  SelahRemoteConfig copyWith({
    bool? enableTopicTabs,
    int? silenceGapSeconds,
    String? defaultTranslation,
    String? announcementBannerText,
    String? feedbackEmailRecipient,
    bool? enableEmojiFeedback,
    bool? feedbackBoardEnabled,
    bool? featureVotingEnabled,
  }) {
    return SelahRemoteConfig(
      enableTopicTabs: enableTopicTabs ?? this.enableTopicTabs,
      silenceGapSeconds: silenceGapSeconds ?? this.silenceGapSeconds,
      defaultTranslation: defaultTranslation ?? this.defaultTranslation,
      announcementBannerText: announcementBannerText ?? this.announcementBannerText,
      feedbackEmailRecipient: feedbackEmailRecipient ?? this.feedbackEmailRecipient,
      enableEmojiFeedback: enableEmojiFeedback ?? this.enableEmojiFeedback,
      feedbackBoardEnabled: feedbackBoardEnabled ?? this.feedbackBoardEnabled,
      featureVotingEnabled: featureVotingEnabled ?? this.featureVotingEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'enable_topic_tabs': enableTopicTabs,
        'silence_gap_seconds': silenceGapSeconds,
        'default_translation': defaultTranslation,
        'announcement_banner_text': announcementBannerText,
        'feedback_email_recipient': feedbackEmailRecipient,
        'enable_emoji_feedback': enableEmojiFeedback,
        'feedback_board_enabled': feedbackBoardEnabled,
        'feature_voting_enabled': featureVotingEnabled,
      };

  factory SelahRemoteConfig.fromJson(Map<String, dynamic> json) {
    return SelahRemoteConfig(
      enableTopicTabs: (json['enable_topic_tabs'] as bool?) ?? kEnableTopicTabsEnv,
      silenceGapSeconds: (json['silence_gap_seconds'] as num?)?.toInt() ?? 4,
      defaultTranslation: (json['default_translation'] as String?) ?? 'BSB',
      announcementBannerText: (json['announcement_banner_text'] as String?) ?? '',
      feedbackEmailRecipient:
          (json['feedback_email_recipient'] as String?) ?? 'neilwarner+selah@gmail.com',
      enableEmojiFeedback: (json['enable_emoji_feedback'] as bool?) ?? true,
      feedbackBoardEnabled: (json['feedback_board_enabled'] as bool?) ?? true,
      featureVotingEnabled: (json['feature_voting_enabled'] as bool?) ?? false,
    );
  }
}

/// Service managing dynamic Firebase Remote Config parameters with offline caching
/// and graceful fallbacks.
class RemoteConfigService {
  static const String _prefCacheKey = 'selah_remote_config_cache';

  final Dio _dio;
  final SharedPreferences? prefs;

  Map<String, dynamic> _currentValues = {};
  SelahRemoteConfig _config = const SelahRemoteConfig();

  RemoteConfigService({Dio? dio, this.prefs})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 6),
              ),
            );

  SelahRemoteConfig get currentConfig => _config;

  /// Initialize from offline disk cache or embedded defaults
  Future<void> init() async {
    try {
      if (prefs != null) {
        final cached = prefs!.getString(_prefCacheKey);
        if (cached != null) {
          final decoded = jsonDecode(cached) as Map<String, dynamic>;
          _currentValues = decoded;
          _config = SelahRemoteConfig.fromJson(decoded);
          AppLogger.info('⚙️ [REMOTE CONFIG]: Loaded cached configuration');
          return;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached remote config: $e');
    }

    _config = const SelahRemoteConfig();
    _currentValues = _config.toJson();
    AppLogger.info('⚙️ [REMOTE CONFIG]: Initialized with defaults');
  }

  /// Synchronize remote parameters from Firestore / Remote Config endpoint
  Future<SelahRemoteConfig> fetchAndActivate() async {
    try {
      final url =
          'https://firestore.googleapis.com/v1/projects/$kFirestoreProjectId/databases/(default)/documents/app_config/remote_config';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final fields = response.data['fields'] as Map<String, dynamic>?;
        if (fields != null) {
          final parsed = <String, dynamic>{};

          if (fields['enable_topic_tabs']?['booleanValue'] != null) {
            parsed['enable_topic_tabs'] = fields['enable_topic_tabs']['booleanValue'];
          }
          if (fields['silence_gap_seconds']?['integerValue'] != null) {
            parsed['silence_gap_seconds'] =
                int.tryParse(fields['silence_gap_seconds']['integerValue'].toString()) ?? 4;
          }
          if (fields['default_translation']?['stringValue'] != null) {
            parsed['default_translation'] = fields['default_translation']['stringValue'];
          }
          if (fields['announcement_banner_text']?['stringValue'] != null) {
            parsed['announcement_banner_text'] =
                fields['announcement_banner_text']['stringValue'];
          }
          if (fields['feedback_email_recipient']?['stringValue'] != null) {
            parsed['feedback_email_recipient'] =
                fields['feedback_email_recipient']['stringValue'];
          }
          if (fields['enable_emoji_feedback']?['booleanValue'] != null) {
            parsed['enable_emoji_feedback'] = fields['enable_emoji_feedback']['booleanValue'];
          }

          _currentValues = {..._currentValues, ...parsed};
          _config = SelahRemoteConfig.fromJson(_currentValues);

          if (prefs != null) {
            await prefs!.setString(_prefCacheKey, jsonEncode(_config.toJson()));
          }
          AppLogger.info('⚙️ [REMOTE CONFIG]: Successfully refreshed and activated');
        }
      }
    } catch (e) {
      AppLogger.info('⚙️ [REMOTE CONFIG]: Using cached/default configuration ($e)');
    }

    return _config;
  }

  String getString(String key) => (_currentValues[key] ?? '').toString();
  int getInt(String key) => int.tryParse(_currentValues[key]?.toString() ?? '') ?? 0;
  bool getBool(String key) => _currentValues[key] == true;
}

/// Riverpod provider for RemoteConfigService
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

/// Notifier to broadcast reactive RemoteConfig updates across the widget tree
class RemoteConfigNotifier extends Notifier<SelahRemoteConfig> {
  @override
  SelahRemoteConfig build() {
    final service = ref.watch(remoteConfigServiceProvider);
    Future.microtask(() => _initAndRefresh(service));
    return service.currentConfig;
  }

  Future<void> _initAndRefresh(RemoteConfigService service) async {
    await service.init();
    state = service.currentConfig;
    final refreshed = await service.fetchAndActivate();
    state = refreshed;
  }

  Future<void> refresh() async {
    final service = ref.read(remoteConfigServiceProvider);
    final refreshed = await service.fetchAndActivate();
    state = refreshed;
  }
}

final remoteConfigProvider =
    NotifierProvider<RemoteConfigNotifier, SelahRemoteConfig>(
  RemoteConfigNotifier.new,
);
