import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../logging/app_logger.dart';

/// Aggregates client device, operating system, and application metadata
/// for attaching to feedback and error diagnostics.
class AppDeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Collects a unified map of metadata safe for telemetry and pre-triage.
  static Future<Map<String, dynamic>> getClientContext() async {
    final Map<String, dynamic> context = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    };

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      context['app_version'] = '0.2.4';
      context['build_number'] = '1';
      context['package_name'] = 'com.example.selah_prototype_audio_13sep2026';
      context['device_model'] = 'TestDevice';
      return context;
    }

    try {
      final pkg = await PackageInfo.fromPlatform();
      context['app_version'] = pkg.version;
      context['build_number'] = pkg.buildNumber;
      context['package_name'] = pkg.packageName;
    } catch (e) {
      context['app_version'] = '0.2.4';
      context['build_number'] = '1';
    }

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        context['browser_name'] = webInfo.browserName.name;
        context['user_agent'] = webInfo.userAgent;
        context['platform_str'] = webInfo.platform;
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
      }
    } catch (e) {
      AppLogger.warning('Device telemetry probe partial error: $e');
    }

    return context;
  }
}
