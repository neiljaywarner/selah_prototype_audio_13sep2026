import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/analytics/analytics_wrapper.dart';
import 'src/core/analytics/aptabase_provider.dart';
import 'src/core/analytics/firebase_analytics_provider.dart';
import 'src/core/analytics/posthog_provider.dart';
import 'src/core/constants/api_constants.dart';
import 'src/core/logging/app_logger.dart';
import 'src/core/preferences/user_preferences.dart';
import 'src/core/remote_config/remote_config_service.dart';

void main() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  // Multi-Provider Analytics Engine
  final aptabaseProvider = AptabaseAnalyticsProvider(appKey: kAptabaseAppKey);
  final firebaseProvider = FirebaseAnalyticsProvider();
  final posthogProvider = PostHogAnalyticsProvider(
    apiKey: kPostHogApiKey,
    host: kPostHogHost,
  );

  final analyticsWrapper = AnalyticsWrapper([
    aptabaseProvider,
    firebaseProvider,
    posthogProvider,
  ]);

  await analyticsWrapper.init();
  AppLogger.init(analyticsWrapper);

  final sharedPreferences = await SharedPreferences.getInstance();

  final remoteConfig = RemoteConfigService(prefs: sharedPreferences);
  await remoteConfig.init();

  AppLogger.info('Selah Scripture Audio Meditation v0.2 Started.');
  AppLogger.info(
    'API.Bible Key status: ${kApiBibleKey == "REDACTED" ? "REDACTED (Set via --dart-define)" : "CONFIGURED (length: ${kApiBibleKey.length})"}',
  );
  AppLogger.info(
    'Aptabase Key status: ${kAptabaseAppKey == "REDACTED" ? "REDACTED (Set via --dart-define)" : "CONFIGURED (length: ${kAptabaseAppKey.length})"}',
  );
  AppLogger.info('Firebase Installations ID: ${firebaseProvider.installationId}');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
      ],
      child: const SelahApp(),
    ),
  );
}
