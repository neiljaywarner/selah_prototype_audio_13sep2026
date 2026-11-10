/// Shared passage references and the opening words tests assert on screen.
///
/// The strings are the public-domain BSB wording already shipped with the
/// featured chapters. They are not a second copy of the audio files.
abstract final class PassageFixtures {
  static const corinthiansReference = '1 Cor 13:4–7';
  static const corinthiansOpening = 'Love is patient, love is kind';
  static const matthewReference = 'Matt 11:28–30';
  static const psalmReference = 'Psalm 23';
  static const unknownReference = 'NotABook 99';

  /// Short stand-in verses for a scripted ESV client. Not the copyrighted text.
  static const esvVerseStubs = <String, String>{
    '1 Cor 13:4': 'Love is patient.',
    '1 Cor 13:5': 'It does not envy.',
    '1 Cor 13:6': 'It does not rejoice at wrongdoing.',
    '1 Cor 13:7': 'Love bears all things.',
  };
}
