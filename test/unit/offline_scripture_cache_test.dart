import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/cache/offline_scripture_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineScriptureCache Tests', () {
    test('Embedded public domain bank returns BSB and WEB chapters offline', () {
      final cache = OfflineScriptureCache(null);

      // BSB John 1
      expect(cache.hasOfflineText('BSB', 'JHN', 1), isTrue);
      final bsbJohn1 = cache.getOfflineText('BSB', 'JHN', 1);
      expect(bsbJohn1, isNotNull);
      expect(bsbJohn1, contains('Word was God'));

      // WEB Psalms 126
      expect(cache.hasOfflineText('WEB', 'PSA', 126), isTrue);
      final webPs126 = cache.getOfflineText('WEB', 'PSA', 126);
      expect(webPs126, isNotNull);
      expect(webPs126, contains('Zion'));

      // WEB Philippians 4
      expect(cache.hasOfflineText('WEB', 'PHP', 4), isTrue);
      final webPhp4 = cache.getOfflineText('WEB', 'PHP', 4);
      expect(webPhp4, isNotNull);
      expect(webPhp4, contains('Rejoice in the Lord always'));

      // 1 Corinthians 13
      expect(cache.hasOfflineText('BSB', '1CO', 13), isTrue);
      final bsb1Co13 = cache.getOfflineText('BSB', '1CO', 13);
      expect(bsb1Co13, isNotNull);
      expect(bsb1Co13, contains('Love is patient'));

      // Licensed NIV is never offline cached
      expect(cache.hasOfflineText('NIV', 'JHN', 1), isFalse);
      expect(cache.getOfflineText('NIV', 'JHN', 1), isNull);
    });

    test('Saves and loads offline public domain scripture from disk cache', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = OfflineScriptureCache(prefs);

      // Save a custom chapter to disk
      const customChapterText = 'Hear, O Israel: The LORD our God, the LORD is one.';
      await cache.saveOfflineToDisk('WEB', 'DEU', 6, customChapterText);

      expect(cache.hasOfflineText('WEB', 'DEU', 6), isTrue);
      expect(cache.getOfflineText('WEB', 'DEU', 6), equals(customChapterText));
    });
  });
}
