import 'package:shared_preferences/shared_preferences.dart';
import '../logging/app_logger.dart';

/// Offline Disk Cache for Public Domain / Open Source scripture translations (BSB, WEB).
///
/// Ensures full functionality in Airplane Mode without network connectivity.
class OfflineScriptureCache {
  OfflineScriptureCache(this._prefs);
  final SharedPreferences? _prefs;

  static const _prefix = 'selah.offline_scripture.';

  static String _cacheKey(String translation, String bookCode, int chapter) =>
      '$_prefix${translation.toUpperCase()}.${bookCode.toUpperCase()}.$chapter';

  /// Check if a chapter is available offline in local disk storage
  bool hasOfflineText(String translation, String bookCode, int chapter) {
    final tr = translation.toUpperCase();
    if (tr != 'BSB' && tr != 'WEB') return false; // NIV is licensed, not cached offline
    final key = _cacheKey(translation, bookCode, chapter);
    if (_prefs?.containsKey(key) ?? false) return true;
    return _embeddedPublicDomainBank.containsKey('$tr.${bookCode.toUpperCase()}.$chapter');
  }

  /// Retrieve cached scripture text from disk or bundled offline bank
  String? getOfflineText(String translation, String bookCode, int chapter) {
    final tr = translation.toUpperCase();
    if (tr != 'BSB' && tr != 'WEB') return null;

    final key = _cacheKey(translation, bookCode, chapter);
    final diskContent = _prefs?.getString(key);
    if (diskContent != null && diskContent.trim().isNotEmpty) {
      AppLogger.info('Offline Cache Hit (disk): $key');
      return diskContent;
    }

    final embedded = _embeddedPublicDomainBank['$tr.${bookCode.toUpperCase()}.$chapter'];
    if (embedded != null) {
      AppLogger.info('Offline Cache Hit (embedded public domain bank): $tr.${bookCode.toUpperCase()}.$chapter');
      return embedded;
    }

    return null;
  }

  /// Save public domain text to local disk cache (persists to SharedPreferences / disk storage)
  Future<void> saveOfflineToDisk(String translation, String bookCode, int chapter, String text) async {
    final tr = translation.toUpperCase();
    if (tr != 'BSB' && tr != 'WEB') return; // Do not disk-cache restricted translations

    final key = _cacheKey(translation, bookCode, chapter);
    await _prefs?.setString(key, text);
    AppLogger.info('Cached public domain scripture to disk: $key (${text.length} chars)');
  }

  /// Bundled offline scripture bank for public domain BSB and WEB
  static final Map<String, String> _embeddedPublicDomainBank = {
    // John 1
    'BSB.JHN.1':
        'In the beginning was the Word, and the Word was with God, and the Word was God. He was with God in the beginning. Through Him all things were made, and without Him nothing was made that has been made. In Him was life, and that life was the light of men. The Light shines in the darkness, and the darkness has not overcome it...',
    'WEB.JHN.1':
        'In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made through him. Without him was not anything made that has been made. In him was life, and the life was the light of men. The light shines in the darkness, and the darkness hasn\'t overcome it...',

    // Colossians 1
    'BSB.COL.1':
        'Paul, an apostle of Christ Jesus by the will of God, and Timothy our brother, to the saints and faithful brothers in Christ at Colossae: Grace to you and peace from God our Father. We always thank God, the Father of our Lord Jesus Christ, when we pray for you, since we heard of your faith in Christ Jesus and your love for all the saints...',
    'WEB.COL.1':
        'Paul, an apostle of Christ Jesus through the will of God, and Timothy our brother, to the saints and faithful brothers in Christ at Colossae: Grace to you and peace from God our Father. We give thanks to God the Father of our Lord Jesus Christ, praying always for you, having heard of your faith in Christ Jesus, and of the love which you have toward all the saints...',

    // Psalms 23
    'BSB.PSA.23':
        'The LORD is my shepherd; I shall not want. He makes me lie down in green pastures; He leads me beside quiet waters. He restores my soul; He guides me in the paths of righteousness for His name’s sake. Even though I walk through the valley of the shadow of death, I will fear no evil, for You are with me; Your rod and Your staff, they comfort me...',
    'WEB.PSA.23':
        'Yahweh is my shepherd: I shall have no lack. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul. He guides me in the paths of righteousness for his name\'s sake. Even though I walk through the valley of the shadow of death, I will fear no evil, for you are with me. Your rod and your staff, they comfort me...',

    // Psalms 126
    'BSB.PSA.126':
        'When the LORD restored the captives of Zion, we were like those who dream. Then our mouth was filled with laughter, and our tongue with shouts of joy. Then it was said among the nations, "The LORD has done great things for them." The LORD has done great things for us; we are filled with joy. Restore our fortunes, O LORD, like streams in the Negev. Those who sow in tears will reap with shouts of joy...',
    'WEB.PSA.126':
        'When Yahweh brought back the captivity of Zion, we were like those who dream. Then our mouth was filled with laughter, and our tongue with singing. Then they said among the nations, "Yahweh has done great things for them." Yahweh has done great things for us, and we are glad. Turn again our captivity, Yahweh, as the streams in the South. Those who sow in tears will reap in joy...',

    // Philippians 4
    'BSB.PHP.4':
        'Rejoice in the Lord always. I will say it again: Rejoice! Let your gentleness be apparent to all. The Lord is near. Be anxious for nothing, but in everything, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus. Finally, brothers, whatever is true, whatever is honorable, whatever is right, whatever is pure, whatever is lovely, whatever is admirable—if anything is excellent or praiseworthy—think on these things...',
    'WEB.PHP.4':
        'Rejoice in the Lord always! Again I will say, Rejoice! Let your gentleness be known to all men. The Lord is at hand. In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God. And the peace of God, which surpasses all understanding, will guard your hearts and your thoughts in Christ Jesus. Finally, brothers, whatever things are true, whatever things are honorable, whatever things are just, whatever things are pure, whatever things are lovely, whatever things are of good report; if there is any virtue, and if there is any praise, think about these things...',

    // Romans 8
    'BSB.ROM.8':
        'Therefore, there is now no condemnation for those who are in Christ Jesus. For in Christ Jesus the law of the Spirit of life set you free from the law of sin and death. For what the law was powerless to do in that it was weakened by the flesh, God did by sending His own Son in the likeness of sinful man, as an offering for sin. He condemned sin in the flesh, so that the righteous standard of the law might be fulfilled in us, who do not walk according to the flesh but according to the Spirit...',
    'WEB.ROM.8':
        'There is therefore now no condemnation to those who are in Christ Jesus, who don\'t walk according to the flesh, but according to the Spirit. For the law of the Spirit of life in Christ Jesus made me free from the law of sin and of death. For what the law couldn\'t do, in that it was weak through the flesh, God did, sending his own Son in the likeness of sinful flesh and for sin, he condemned sin in the flesh; that the ordinance of the law might be fulfilled in us, who walk not after the flesh, but after the Spirit...',

    // 1 Corinthians 13
    'BSB.1CO.13':
        'Love is patient, love is kind. It does not envy, it does not boast, it is not proud. It is not rude, it is not self-seeking, it is not easily angered, it keeps no account of wrongs. Love does not delight in evil but rejoices with the truth. It bears all things, believes all things, hopes all things, endures all things.',
    'WEB.1CO.13':
        'Love is patient, love is kind. Love does not envy. Love does not brag, is not proud, does not behave itself inappropriately, does not seek its own way, is not provoked, takes no account of evil; doesn\'t rejoice in unrighteousness, but rejoices with the truth; bears all things, believes all things, hopes all things, endures all things.',
  };
}
