import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// Web integration test driver.
/// Run with: flutter drive --driver=test_driver/web_driver.dart --target=integration_test/app_test.dart -d chrome
void main() {
  FlutterDriver? driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver?.close();
  });

  test('App launches on web', () async {
    // Just verify connection works
    final health = await driver?.checkHealth();
    expect(health?.status, HealthStatus.ok);
  });
}
