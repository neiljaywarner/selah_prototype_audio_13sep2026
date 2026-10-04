import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/analytics/analytics_service.dart';
import 'src/core/constants/api_constants.dart';
import 'src/core/logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final analytics = AptabaseAnalyticsProvider(appKey: kAptabaseAppKey);
  await analytics.init();
  AppLogger.init(analytics);

  AppLogger.info('Selah Web Audio Player Started.');
  AppLogger.info(
    'API.Bible Key status: ${kApiBibleKey == "REDACTED" ? "REDACTED (Set via --dart-define)" : "CONFIGURED"}',
  );
  AppLogger.info(
    'Aptabase Key status: ${kAptabaseAppKey == "REDACTED" ? "REDACTED (Set via --dart-define)" : "CONFIGURED"}',
  );

  runApp(const ProviderScope(child: SelahApp()));
}
