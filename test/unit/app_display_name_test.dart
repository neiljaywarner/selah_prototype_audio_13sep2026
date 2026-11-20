import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the launcher name is Selah and the Android application id is unchanged',
    () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final iosPlist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(gradle, contains('applicationId = "app.selahword.audio"'));

      final label = RegExp('android:label="([^"]+)"').firstMatch(manifest);
      expect(label, isNotNull, reason: manifest);
      expect(label!.group(1), 'Selah');
      expect(manifest, isNot(contains('selah_prototype_audio_13sep2026')));

      expect(_plistValue(iosPlist, 'CFBundleDisplayName'), 'Selah');
      expect(_plistValue(iosPlist, 'CFBundleName'), 'Selah');
      expect(iosPlist, isNot(contains('selah_prototype_audio_13sep2026')));
      expect(iosPlist, isNot(contains('Selah Prototype')));
    },
  );
}

String? _plistValue(String plist, String key) {
  final match = RegExp('<key>$key</key>\\s*<string>([^<]*)</string>')
      .firstMatch(plist);
  return match?.group(1);
}
