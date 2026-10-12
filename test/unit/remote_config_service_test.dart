import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/remote_config/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemoteConfigService & SelahRemoteConfig Unit Tests (#51)', () {
    test('SelahRemoteConfig defaults match requirements', () {
      const config = SelahRemoteConfig();
      expect(config.silenceGapSeconds, equals(4));
      expect(config.defaultTranslation, equals('BSB'));
      expect(config.feedbackEmailRecipient, equals('neilwarner+selah@gmail.com'));
      expect(config.enableEmojiFeedback, isTrue);
      expect(config.feedbackBoardEnabled, isTrue);
      expect(config.featureVotingEnabled, isFalse);
      expect(config.announcementBannerText, isEmpty);
    });

    test('SelahRemoteConfig serialization round-trip', () {
      const config = SelahRemoteConfig(
        enableTopicTabs: true,
        silenceGapSeconds: 6,
        defaultTranslation: 'WEB',
        announcementBannerText: 'Welcome to Selah v0.3.0!',
        feedbackEmailRecipient: 'neilwarner+selah@gmail.com',
        enableEmojiFeedback: true,
        featureVotingEnabled: true,
      );

      final json = config.toJson();
      final restored = SelahRemoteConfig.fromJson(json);

      expect(restored.enableTopicTabs, isTrue);
      expect(restored.silenceGapSeconds, equals(6));
      expect(restored.defaultTranslation, equals('WEB'));
      expect(restored.announcementBannerText, equals('Welcome to Selah v0.3.0!'));
      expect(restored.feedbackEmailRecipient, equals('neilwarner+selah@gmail.com'));
      expect(restored.featureVotingEnabled, isTrue);
    });

    test('RemoteConfigService initializes with defaults when cache is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final service = RemoteConfigService(prefs: prefs);
      await service.init();

      expect(service.currentConfig.silenceGapSeconds, equals(4));
      expect(service.currentConfig.defaultTranslation, equals('BSB'));
      expect(service.getString('default_translation'), equals('BSB'));
      expect(service.getInt('silence_gap_seconds'), equals(4));
    });

    test('RemoteConfigService restores cached config from SharedPreferences', () async {
      final cachedJson = {
        'enable_topic_tabs': true,
        'silence_gap_seconds': 5,
        'default_translation': 'WEB',
        'announcement_banner_text': 'Server maintenance tonight',
        'feedback_email_recipient': 'neilwarner+selah@gmail.com',
        'enable_emoji_feedback': true,
      };

      SharedPreferences.setMockInitialValues({
        'selah_remote_config_cache': jsonEncode(cachedJson),
      });
      final prefs = await SharedPreferences.getInstance();

      final service = RemoteConfigService(prefs: prefs);
      await service.init();

      expect(service.currentConfig.enableTopicTabs, isTrue);
      expect(service.currentConfig.silenceGapSeconds, equals(5));
      expect(service.currentConfig.defaultTranslation, equals('WEB'));
      expect(service.currentConfig.announcementBannerText, equals('Server maintenance tonight'));
    });
  });
}
