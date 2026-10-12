import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/audio/bundled_audio_service.dart';

void main() {
  group('BundledAudioService', () {
    test('identifies bundled audio for BSB curated passages', () {
      expect(BundledAudioService.hasBundledAudio('BSB', 'MAT', 11), isTrue);
      expect(BundledAudioService.hasBundledAudio('BSB', '1CO', 13), isTrue);
      expect(BundledAudioService.hasBundledAudio('BSB', 'ROM', 8), isTrue);
      expect(BundledAudioService.hasBundledAudio('BSB', 'PSA', 23), isTrue);
      expect(BundledAudioService.hasBundledAudio('BSB', 'PSA', 62), isTrue);
      expect(BundledAudioService.hasBundledAudio('BSB', 'COL', 1), isTrue);

      expect(
        BundledAudioService.getBundledAudioPath('BSB', 'MAT', 11),
        equals('assets/audio/BSB/MAT_11.mp3'),
      );
      expect(
        BundledAudioService.getBundledAudioPath('BSB', '1CO', 13),
        equals('assets/audio/BSB/1CO_13.mp3'),
      );
    });

    test('identifies bundled audio for WEB curated passages', () {
      expect(BundledAudioService.hasBundledAudio('WEB', 'MAT', 11), isTrue);
      expect(BundledAudioService.hasBundledAudio('WEB', '1CO', 13), isTrue);
      expect(BundledAudioService.hasBundledAudio('WEB', 'ROM', 8), isTrue);
      expect(BundledAudioService.hasBundledAudio('WEB', 'COL', 1), isTrue);

      expect(
        BundledAudioService.getBundledAudioPath('WEB', 'MAT', 11),
        equals('assets/audio/WEB/MAT_11.mp3'),
      );
    });

    test('returns false and null for non-curated or proprietary passages', () {
      // Non-curated chapters
      expect(BundledAudioService.hasBundledAudio('BSB', 'GEN', 1), isFalse);
      expect(BundledAudioService.getBundledAudioPath('BSB', 'GEN', 1), isNull);

      // Proprietary NIV is never bundled locally for copyright compliance
      expect(BundledAudioService.hasBundledAudio('NIV', 'MAT', 11), isFalse);
      expect(BundledAudioService.getBundledAudioPath('NIV', 'MAT', 11), isNull);
    });

    test('is case-insensitive for translation and book code', () {
      expect(BundledAudioService.hasBundledAudio('bsb', 'mat', 11), isTrue);
      expect(
        BundledAudioService.getBundledAudioPath('web', '1co', 13),
        equals('assets/audio/WEB/1CO_13.mp3'),
      );
    });
  });
}
