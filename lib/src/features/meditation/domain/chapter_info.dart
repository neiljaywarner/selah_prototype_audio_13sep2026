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
    bookCode: 'COL',
    bookName: 'Colossians',
    chapterNumber: 1,
    audioStreamUrl:
        'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=ambient-piano-10781.mp3',
    textContent:
        'Paul, an apostle of Christ Jesus through the will of God, and Timothy our brother, to the saints and faithful brothers in Christ at Colossae: Grace to you and peace from God our Father...',
  ),
  const ChapterInfo(
    bookCode: 'JHN',
    bookName: 'John',
    chapterNumber: 1,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Jhn001.mp3',
    textContent:
        'In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made through him...',
  ),
  const ChapterInfo(
    bookCode: 'PSA',
    bookName: 'Psalm',
    chapterNumber: 23,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps023.mp3',
    textContent:
        'Yahweh is my shepherd: I shall have no lack. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul...',
  ),
];
