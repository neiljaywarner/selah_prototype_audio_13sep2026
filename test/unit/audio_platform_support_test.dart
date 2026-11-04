import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/telemetry/device_info_service.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/analytics/web_gtag_helper.dart';

void main() {
  group('Audio Platform Support & Environment Telemetry Matrix', () {
    test('Environment flags accurately represent execution mode', () {
      expect(isMarionetteDriving, isFalse);
      expect(isMaestroDriving, isFalse);
      expect(isPatrolDriving, isFalse);
      expect(isPwaRunning, isFalse);
      expect(isWebApkRunning, isFalse);
    });

    test('AppDeviceInfoService context contains platform audio capabilities', () async {
      final context = await AppDeviceInfoService.getClientContext();
      expect(context.containsKey('platform'), isTrue);
      expect(context.containsKey('is_pwa'), isTrue);
      expect(context.containsKey('is_webapk'), isTrue);
      expect(context.containsKey('is_debug_mode'), isTrue);
    });
  });
}
