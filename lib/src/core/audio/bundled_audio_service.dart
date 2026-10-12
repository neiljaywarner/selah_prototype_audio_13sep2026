import '../logging/app_logger.dart';

/// Service managing offline bundled human narrator audio files for open-source translations (BSB, WEB).
///
/// Enables zero-network, zero-API-key human narration for curated meditation passages.
class BundledAudioService {
  static const Set<String> _bundledChapters = {
    // Berean Standard Bible (BSB) - Public Domain / CC0 Open Audio
    'BSB.1CO.13',
    'BSB.COL.1',
    'BSB.MAT.11',
    'BSB.PSA.23',
    'BSB.PSA.62',
    'BSB.ROM.8',

    // World English Bible (WEB) - Public Domain Open Audio
    'WEB.1CO.13',
    'WEB.COL.1',
    'WEB.MAT.11',
    'WEB.ROM.8',
  };

  /// Returns true if an offline human narrator MP3 is bundled for this passage.
  static bool hasBundledAudio(String translation, String bookCode, int chapterNumber) {
    final key = '${translation.toUpperCase()}.${bookCode.toUpperCase()}.$chapterNumber';
    return _bundledChapters.contains(key);
  }

  /// Returns the asset path (e.g. 'assets/audio/BSB/MAT_11.mp3') if bundled, or null.
  static String? getBundledAudioPath(String translation, String bookCode, int chapterNumber) {
    if (!hasBundledAudio(translation, bookCode, chapterNumber)) return null;
    final path = 'assets/audio/${translation.toUpperCase()}/${bookCode.toUpperCase()}_$chapterNumber.mp3';
    AppLogger.info('Found bundled human narrator audio: $path');
    return path;
  }
}
