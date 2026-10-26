import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import '../logging/app_logger.dart';
import '../analytics/web_gtag_helper.dart';

/// Aggregates client device, operating system, and application metadata
/// for attaching to feedback and error diagnostics.
class AppDeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Collects a unified map of metadata safe for telemetry and pre-triage.
  static Future<Map<String, dynamic>> getClientContext({Dio? dioClient}) async {
    final Map<String, dynamic> context = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'is_debug_mode': kDebugMode,
      'is_marionette': isMarionetteDriving,
      'is_maestro': isMaestroDriving,
      'is_patrol': isPatrolDriving,
      'is_pwa': isPwaRunning,
      'is_webapk': isWebApkRunning,
    };

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      context['app_version'] = '0.4.1';
      context['build_number'] = '53';
      context['package_name'] = 'com.example.selah_prototype_audio_13sep2026';
      context['device_model'] = 'TestDevice';
      context['public_ip'] = '127.0.0.1';
      return context;
    }

    try {
      final pkg = await PackageInfo.fromPlatform();
      context['app_version'] = pkg.version;
      context['build_number'] = pkg.buildNumber;
      context['package_name'] = pkg.packageName;
    } catch (e) {
      context['app_version'] = '0.4.1';
      context['build_number'] = '53';
    }

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        context['browser_name'] = webInfo.browserName.name;
        context['user_agent'] = webInfo.userAgent;
        context['platform_str'] = webInfo.platform;
        context['device_model'] = '${webInfo.browserName.name} (${webInfo.platform})';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        context['device_model'] = androidInfo.model;
        context['manufacturer'] = androidInfo.manufacturer;
        context['android_version'] = androidInfo.version.release;
        context['sdk_int'] = androidInfo.version.sdkInt;
        context['is_physical_device'] = androidInfo.isPhysicalDevice;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        context['device_model'] = iosInfo.utsname.machine;
        context['system_version'] = iosInfo.systemVersion;
        context['name'] = iosInfo.name;
        context['is_physical_device'] = iosInfo.isPhysicalDevice;
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        context['os_version'] = macInfo.osRelease;
        context['model'] = macInfo.model;
        context['device_model'] = 'macOS ${macInfo.osRelease}';
      }
    } catch (e) {
      AppLogger.warning('Device telemetry probe partial error: $e');
    }

    // Resolve public IP address for triage attribution (with 2-second timeout)
    try {
      final dio = dioClient ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 2),
              receiveTimeout: const Duration(seconds: 2),
            ),
          );
      final ipRes = await dio.get('https://api.ipify.org?format=json');
      if (ipRes.statusCode == 200 && ipRes.data != null) {
        if (ipRes.data is Map) {
          context['public_ip'] = ipRes.data['ip']?.toString() ?? 'unavailable';
        } else if (ipRes.data is String) {
          context['public_ip'] = ipRes.data.toString().trim();
        }
      }
    } catch (_) {
      context['public_ip'] = 'unavailable';
    }

    return context;
  }
}
