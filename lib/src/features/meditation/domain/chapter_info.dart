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
    bookCode: 'ROM',
    bookName: 'Romans',
    chapterNumber: 8,
    audioStreamUrl: '',
    textContent:
        'There is therefore now no condemnation for those who are in Christ Jesus. For the law of the Spirit of life in Christ Jesus has set you free...',
  ),
];
