import 'package:flutter/foundation.dart';
import 'analytics_service.dart';
import 'web_gtag_helper.dart';

class FirebaseAnalyticsProvider implements AnalyticsService {
  bool _initialized = false;
  String? _installationId;
  final Map<String, String> _userProperties = {};

  String? get installationId => _installationId;
  Map<String, String> get userProperties => Map.unmodifiable(_userProperties);

  @override
  Future<void> init() async {
    try {
      _installationId = 'inst_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
      _initialized = true;

      // Set default user properties
      await setUserProperty('k_debug_mode', kDebugMode.toString());
      await setUserProperty('is_marionette', isMarionetteDriving.toString());
      await setUserProperty('is_maestro', isMaestroDriving.toString());
      await setUserProperty('is_patrol', isPatrolDriving.toString());
      await setUserProperty('is_pwa', isPwaRunning.toString());
      await setUserProperty('is_webapk', isWebApkRunning.toString());

      debugPrint('🔥 [FIREBASE ANALYTICS]: Initialized. Installations ID: $_installationId');
    } catch (e) {
      debugPrint('🔴 [FIREBASE ANALYTICS INIT FAILED]: $e');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    _userProperties[name] = value;
    if (kIsWeb) {
      setGtagUserProperty(name, value);
    }
    debugPrint('🔥 [FIREBASE USER PROPERTY]: $name = $value');
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (!_initialized) return;
    try {
      final augmentedPayload = <String, dynamic>{
        'k_debug_mode': kDebugMode,
        'is_marionette': isMarionetteDriving,
        'is_maestro': isMaestroDriving,
        'is_patrol': isPatrolDriving,
        'is_pwa': isPwaRunning,
        'is_webapk': isWebApkRunning,
        ...?properties,
      };

      if (kIsWeb) {
        sendGtagEvent(eventName, augmentedPayload);
      }
      debugPrint('🔥 [FIREBASE EVENT]: $eventName => $augmentedPayload');
    } catch (e) {
      debugPrint('🔴 [FIREBASE EVENT LOG FAILED]: $e');
    }
  }

  @override
  Future<void> logError(
    String errorName, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraProperties,
  }) async {
    if (!_initialized) return;
    try {
      final isFatal = extraProperties?['is_fatal'] == true;
      final crashPayload = <String, dynamic>{
        'installation_id': _installationId ?? 'unknown',
        'k_debug_mode': kDebugMode,
        'is_marionette': isMarionetteDriving,
        'is_maestro': isMaestroDriving,
        'is_patrol': isPatrolDriving,
        'is_pwa': isPwaRunning,
        'is_webapk': isWebApkRunning,
        'error_name': errorName,
        'error_type': extraProperties?['error_type'] ?? error?.runtimeType.toString() ?? 'UnknownError',
        'error_message': error?.toString() ?? errorName,
        'fatal': isFatal,
        ...?extraProperties,
      };
      if (kIsWeb) {
        sendGtagEvent('app_exception', crashPayload);
      }
      debugPrint(
        '🔥 [FIREBASE CRASHLYTICS & ANALYTICS]: app_exception ($errorName) => $crashPayload',
      );
    } catch (e) {
      debugPrint('🔴 [FIREBASE ERROR LOG FAILED]: $e');
    }
  }
}
