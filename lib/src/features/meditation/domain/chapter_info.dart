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
    bookCode: '1CO',
    bookName: '1 Corinthians',
    chapterNumber: 13,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/1Cor013.mp3',
    textContent: 'Love is patient, love is kind. Love does not envy. Love does not brag, is not proud, does not behave itself inappropriately, does not seek its own way...',
  ),
  const ChapterInfo(
    bookCode: 'PSA',
    bookName: 'Psalm',
    chapterNumber: 23,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps023.mp3',
    textContent: 'Yahweh is my shepherd: I shall have no lack. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul...',
  ),
  const ChapterInfo(
    bookCode: 'PSA',
    bookName: 'Psalm',
    chapterNumber: 62,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps062.mp3',
    textContent: 'Truly my soul finds rest in God; my salvation comes from him. Truly he is my rock and my salvation; he is my fortress, I will never be shaken...',
  ),
  const ChapterInfo(
    bookCode: 'MRK',
    bookName: 'Mark',
    chapterNumber: 5,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Mrk005.mp3',
    textContent: 'They came to the other side of the sea, into the country of the Gerasenes. When he had come out of the boat, immediately a man with an unclean spirit met him...',
  ),
  const ChapterInfo(
    bookCode: 'JHN',
    bookName: 'John',
    chapterNumber: 1,
    audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Jhn001.mp3',
    textContent: 'In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made through him...',
  ),
  const ChapterInfo(
    bookCode: 'COL',
    bookName: 'Colossians',
    chapterNumber: 1,
    audioStreamUrl: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=ambient-piano-10781.mp3',
    textContent: 'Paul, an apostle of Christ Jesus through the will of God, and Timothy our brother, to the saints and faithful brothers in Christ at Colossae: Grace to you and peace from God our Father...',
  ),
];
