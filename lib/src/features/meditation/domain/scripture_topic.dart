import 'chapter_info.dart';

class ScriptureTopic {
  final String id;
  final String title;
  final String iconEmoji;
  final String description;
  final List<ChapterInfo> chapters;

  const ScriptureTopic({
    required this.id,
    required this.title,
    required this.iconEmoji,
    required this.description,
    required this.chapters,
  });
}

const List<ScriptureTopic> kDefaultMeditationTopics = [
  ScriptureTopic(
    id: 'featured',
    title: 'Featured',
    iconEmoji: '✨',
    description: 'Curated cornerstone chapters for daily stillness and reflection',
    chapters: [
      ChapterInfo(
        bookCode: 'COL',
        bookName: 'Colossians',
        chapterNumber: 1,
        audioStreamUrl: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=ambient-piano-10781.mp3',
        textContent: 'Paul, an apostle of Christ Jesus through the will of God, and Timothy our brother, to the saints and faithful brothers in Christ at Colossae: Grace to you and peace from God our Father...',
      ),
      ChapterInfo(
        bookCode: 'JHN',
        bookName: 'John',
        chapterNumber: 1,
        audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Jhn001.mp3',
        textContent: 'In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made through him...',
      ),
      ChapterInfo(
        bookCode: 'PSA',
        bookName: 'Psalms',
        chapterNumber: 23,
        audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps023.mp3',
        textContent: 'Yahweh is my shepherd: I shall have no lack. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul...',
      ),
      ChapterInfo(
        bookCode: '1CO',
        bookName: '1 Corinthians',
        chapterNumber: 13,
        audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/1Cor013.mp3',
        textContent: 'Love is patient, love is kind. Love does not envy. Love does not brag, is not proud...',
      ),
      ChapterInfo(
        bookCode: 'MRK',
        bookName: 'Mark',
        chapterNumber: 5,
        audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Mrk005.mp3',
        textContent: 'They came to the other side of the sea, into the country of the Gerasenes...',
      ),
    ],
  ),
  ScriptureTopic(
    id: 'hope',
    title: 'Hope',
    iconEmoji: '🌱',
    description: 'Anchoring in eternal hope and divine renewal',
    chapters: [
      ChapterInfo(
        bookCode: 'ROM',
        bookName: 'Romans',
        chapterNumber: 8,
        audioStreamUrl: '',
        textContent: 'There is therefore now no condemnation to those who are in Christ Jesus... For I consider that the sufferings of this present time are not worthy to be compared with the glory which will be revealed in us.',
      ),
      ChapterInfo(
        bookCode: 'PSA',
        bookName: 'Psalms',
        chapterNumber: 42,
        audioStreamUrl: '',
        textContent: 'As the deer pants for streams of water, so my soul pants for you, God. Why are you in despair, my soul? Why are you disturbed within me? Hope in God! For I shall still praise him.',
      ),
      ChapterInfo(
        bookCode: 'LAM',
        bookName: 'Lamentations',
        chapterNumber: 3,
        audioStreamUrl: '',
        textContent: 'Yahweh’s loving kindnesses indeed never cease, for his compassions never fail. They are new every morning; great is your faithfulness.',
      ),
    ],
  ),
  ScriptureTopic(
    id: 'faith',
    title: 'Faith',
    iconEmoji: '🛡️',
    description: 'Building steadfast confidence in God’s character',
    chapters: [
      ChapterInfo(
        bookCode: 'HEB',
        bookName: 'Hebrews',
        chapterNumber: 11,
        audioStreamUrl: '',
        textContent: 'Now faith is the assurance of things hoped for, proof of things not seen. For by this, the elders obtained good testimony. By faith we understand that the universe has been framed by the word of God...',
      ),
      ChapterInfo(
        bookCode: 'ROM',
        bookName: 'Romans',
        chapterNumber: 10,
        audioStreamUrl: '',
        textContent: 'So faith comes by hearing, and hearing by the word of God. But I say, didn’t they hear? Yes, most certainly, "Their sound went out into all the earth, their words to the ends of the world."',
      ),
      ChapterInfo(
        bookCode: 'MRK',
        bookName: 'Mark',
        chapterNumber: 11,
        audioStreamUrl: '',
        textContent: 'Jesus answered them, "Have faith in God. For most certainly I tell you, whoever may tell this mountain, \'Be taken up and cast into the sea,\' and doesn’t doubt in his heart... it will be done."',
      ),
    ],
  ),
  ScriptureTopic(
    id: 'peace',
    title: 'Peace',
    iconEmoji: '🕊️',
    description: 'Surrendering anxiety into transcendent stillness',
    chapters: [
      ChapterInfo(
        bookCode: 'PHP',
        bookName: 'Philippians',
        chapterNumber: 4,
        audioStreamUrl: '',
        textContent: 'In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God. And the peace of God, which surpasses all understanding, will guard your hearts...',
      ),
      ChapterInfo(
        bookCode: 'JHN',
        bookName: 'John',
        chapterNumber: 14,
        audioStreamUrl: '',
        textContent: 'Peace I leave with you. My peace I give to you; not as the world gives, give I to you. Don’t let your heart be troubled, neither let it be fearful.',
      ),
      ChapterInfo(
        bookCode: 'PSA',
        bookName: 'Psalms',
        chapterNumber: 4,
        audioStreamUrl: '',
        textContent: 'In peace I will both lay myself down and sleep, for you, Yahweh, alone make me live in safety.',
      ),
    ],
  ),
  ScriptureTopic(
    id: 'comfort',
    title: 'Comfort',
    iconEmoji: '🕯️',
    description: 'Resting in the tenderness of the Shepherd and Father',
    chapters: [
      ChapterInfo(
        bookCode: 'PSA',
        bookName: 'Psalms',
        chapterNumber: 23,
        audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Ps023.mp3',
        textContent: 'Yahweh is my shepherd: I shall have no lack. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul...',
      ),
      ChapterInfo(
        bookCode: '1CO',
        bookName: '1 Corinthians',
        chapterNumber: 13,
        audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/1Cor013.mp3',
        textContent: 'Love is patient, love is kind. Love does not envy. Love does not brag, is not proud...',
      ),
      ChapterInfo(
        bookCode: 'MRK',
        bookName: 'Mark',
        chapterNumber: 5,
        audioStreamUrl: 'https://ia800203.us.archive.org/11/items/WEB_Audio_Bible/Mrk005.mp3',
        textContent: 'They came to the other side of the sea, into the country of the Gerasenes...',
      ),
      ChapterInfo(
        bookCode: 'PSA',
        bookName: 'Psalms',
        chapterNumber: 46,
        audioStreamUrl: '',
        textContent: 'God is our refuge and strength, a very present help in trouble... "Be still, and know that I am God. I will be exalted among the nations. I will be exalted in the earth."',
      ),
      ChapterInfo(
        bookCode: 'ISA',
        bookName: 'Isaiah',
        chapterNumber: 40,
        audioStreamUrl: '',
        textContent: '"Comfort, comfort my people," says your God... He will feed his flock like a shepherd. He will gather the lambs in his arm, and carry them in his bosom.',
      ),
    ],
  ),
  ScriptureTopic(
    id: 'strength',
    title: 'Strength',
    iconEmoji: '⛰️',
    description: 'Renewing vigor through divine fortitude',
    chapters: [
      ChapterInfo(
        bookCode: 'ISA',
        bookName: 'Isaiah',
        chapterNumber: 41,
        audioStreamUrl: '',
        textContent: 'Don’t you be afraid, for I am with you. Don’t be dismayed, for I am your God. I will strengthen you. Yes, I will help you. Yes, I will uphold you with the right hand of my righteousness.',
      ),
      ChapterInfo(
        bookCode: 'PSA',
        bookName: 'Psalms',
        chapterNumber: 27,
        audioStreamUrl: '',
        textContent: 'Yahweh is my light and my salvation. Whom shall I fear? Yahweh is the strength of my life. Of whom shall I be afraid?',
      ),
      ChapterInfo(
        bookCode: 'EPH',
        bookName: 'Ephesians',
        chapterNumber: 6,
        audioStreamUrl: '',
        textContent: 'Finally, be strong in the Lord, and in the strength of his might. Put on the whole armor of God, that you may be able to stand against the wiles of the devil.',
      ),
    ],
  ),
];
