import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

class FirebaseAnalyticsProvider implements AnalyticsService {
  bool _initialized = false;
  String? _installationId;

  String? get installationId => _installationId;

  @override
  Future<void> init() async {
    try {
      // Simulate/retrieve Firebase installation ID for observability
      _installationId = 'inst_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
      _initialized = true;
      debugPrint('🔥 [FIREBASE ANALYTICS]: Initialized. Installations ID: $_installationId');
    } catch (e) {
      debugPrint('🔴 [FIREBASE ANALYTICS INIT FAILED]: $e');
    }
  }

  @override
  Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (!_initialized) return;
    try {
      debugPrint('🔥 [FIREBASE EVENT]: $eventName => ${properties ?? {}}');
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
      debugPrint('🔥 [FIREBASE ERROR]: $errorName | $error');
    } catch (e) {
      debugPrint('🔴 [FIREBASE ERROR LOG FAILED]: $e');
    }
  }
}
