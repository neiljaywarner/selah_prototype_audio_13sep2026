class ChapterInfo {
  final String bookCode;
  final String bookName;
  final int chapterNumber;
  final String audioStreamUrl;
  final String textContent;

  const ChapterInfo({
    required this.bookCode,
    required this.bookName,
    required this.chapterNumber,
    required this.audioStreamUrl,
    required this.textContent,
  });

  String get reference => '$bookName $chapterNumber';

  ChapterInfo copyWith({
    String? bookCode,
    String? bookName,
    int? chapterNumber,
    String? audioStreamUrl,
    String? textContent,
  }) =>
      ChapterInfo(
        bookCode: bookCode ?? this.bookCode,
        bookName: bookName ?? this.bookName,
        chapterNumber: chapterNumber ?? this.chapterNumber,
        audioStreamUrl: audioStreamUrl ?? this.audioStreamUrl,
        textContent: textContent ?? this.textContent,
      );
}

final List<ChapterInfo> kFeaturedChapters = [
  const ChapterInfo(
    bookCode: 'JHN',
    bookName: 'John',
    chapterNumber: 1,
    audioStreamUrl: '',
    textContent:
        'In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made through him...',
  ),
  const ChapterInfo(
    bookCode: 'COL',
    bookName: 'Colossians',
    chapterNumber: 1,
    audioStreamUrl: '',
    textContent:
        'Paul, an apostle of Christ Jesus through the will of God, and Timothy our brother, to the saints and faithful brothers in Christ at Colossae: Grace to you and peace from God our Father...',
  ),
  const ChapterInfo(
    bookCode: 'PSA',
    bookName: 'Psalms',
    chapterNumber: 23,
    audioStreamUrl: '',
    textContent:
        'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul...',
  ),
  const ChapterInfo(
    bookCode: 'PSA',
    bookName: 'Psalms',
    chapterNumber: 126,
    audioStreamUrl: '',
    textContent:
        'When the LORD brought back the captivity of Zion, we were like those who dream. Then our mouth was filled with laughter, and our tongue with singing...',
  ),
  const ChapterInfo(
    bookCode: 'ROM',
    bookName: 'Romans',
    chapterNumber: 8,
    audioStreamUrl: '',
    textContent:
        'There is therefore now no condemnation for those who are in Christ Jesus. For the law of the Spirit of life in Christ Jesus has set you free...',
  ),
  const ChapterInfo(
    bookCode: 'PHP',
    bookName: 'Philippians',
    chapterNumber: 4,
    audioStreamUrl: '',
    textContent:
        'Rejoice in the Lord always! Again I will say, Rejoice! Let your gentleness be known to all men. The Lord is at hand. In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God...',
  ),
  const ChapterInfo(
    bookCode: '1CO',
    bookName: '1 Corinthians',
    chapterNumber: 13,
    audioStreamUrl: '',
    textContent:
        'If I speak with the languages of men and of angels, but don\'t have love, I have become sounding brass, or a clanging cymbal. Love is patient, love is kind. Love does not envy. Love does not brag, is not proud. It bears all things, believes all things, hopes all things, endures all things. Love never fails...',
  ),
];
