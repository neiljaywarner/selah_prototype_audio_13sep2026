import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Android manifest verifies https share links on selahword.web.app', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(
      gradle,
      contains('applicationId = "app.selahword.audio"'),
    );

    final filter = RegExp(
      r'<intent-filter\s+android:autoVerify="true">([\s\S]*?)</intent-filter>',
    ).firstMatch(manifest);
    expect(filter, isNotNull, reason: manifest);
    final body = filter!.group(1)!;
    expect(body, contains('android.intent.action.VIEW'));
    expect(body, contains('android.intent.category.DEFAULT'));
    expect(body, contains('android.intent.category.BROWSABLE'));
    expect(body, contains('android:scheme="https"'));
    expect(body, contains('android:host="selahword.web.app"'));
    expect(body, contains('android:pathPrefix="/"'));
  });
}
