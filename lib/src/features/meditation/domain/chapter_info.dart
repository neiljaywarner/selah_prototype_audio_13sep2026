class ChapterInfo {
  final String bookCode;
  final String bookName;
  final int chapterNumber;
  final String audioStreamUrl;
  final String textContent;
  final String? displayTitle;

  const ChapterInfo({
    required this.bookCode,
    required this.bookName,
    required this.chapterNumber,
    required this.audioStreamUrl,
    required this.textContent,
    this.displayTitle,
  });

  String get reference => displayTitle ?? '$bookName $chapterNumber';

  ChapterInfo copyWith({
    String? bookCode,
    String? bookName,
    int? chapterNumber,
    String? audioStreamUrl,
    String? textContent,
    String? displayTitle,
  }) =>
      ChapterInfo(
        bookCode: bookCode ?? this.bookCode,
        bookName: bookName ?? this.bookName,
        chapterNumber: chapterNumber ?? this.chapterNumber,
        audioStreamUrl: audioStreamUrl ?? this.audioStreamUrl,
        textContent: textContent ?? this.textContent,
        displayTitle: displayTitle ?? this.displayTitle,
      );
}

final List<ChapterInfo> kFeaturedChapters = [
  const ChapterInfo(
    bookCode: '1CO',
    bookName: '1 Corinthians',
    chapterNumber: 13,
    audioStreamUrl: '',
    textContent:
        'Love is patient, love is kind. It does not envy, it does not boast, it is not proud. It is not rude, it is not self-seeking, it is not easily angered, it keeps no account of wrongs. Love does not delight in evil but rejoices with the truth. It bears all things, believes all things, hopes all things, endures all things.',
    displayTitle: '1 Cor 13:4–7',
  ),
  const ChapterInfo(
    bookCode: 'MAT',
    bookName: 'Matthew',
    chapterNumber: 11,
    audioStreamUrl: '',
    textContent:
        'Come to Me, all you who are weary and burdened, and I will give you rest. Take My yoke upon you and learn from Me; for I am gentle and humble in heart, and you will find rest for your souls. For My yoke is easy and My burden is light.',
    displayTitle: 'Matt 11:28–30',
  ),
  const ChapterInfo(
    bookCode: 'ROM',
    bookName: 'Romans',
    chapterNumber: 8,
    audioStreamUrl: '',
    textContent:
        'What then shall we say in response to these things? If God is for us, who can be against us? He who did not spare His own Son, but gave Him up for us all, how will He not also, along with Him, freely give us all things? Who will bring any charge against God\'s elect? It is God who justifies. Who is there to condemn us? For Christ Jesus, who died, and more than that was raised to life, is at the right hand of God—and He is interceding for us. Who shall separate us from the love of Christ? Shall trouble or distress or persecution or famine or nakedness or danger or sword? As it is written: “For Your sake we face death all day long; we are considered as sheep to be slaughtered.” No, in all these things we are more than conquerors through Him who loved us. For I am convinced that neither death nor life, neither angels nor principalities, neither the present nor the future, nor any powers, neither height nor depth, nor anything else in all creation, will be able to separate us from the love of God that is in Christ Jesus our Lord.',
    displayTitle: 'Rom 8:31–39',
  ),
  const ChapterInfo(
    bookCode: 'PSA',
    bookName: 'Psalms',
    chapterNumber: 23,
    audioStreamUrl: '',
    textContent:
        'The LORD is my shepherd; I shall not want. He makes me lie down in green pastures; He leads me beside quiet waters. He restores my soul; He guides me in the paths of righteousness for His name’s sake. Even though I walk through the valley of the shadow of death, I will fear no evil, for You are with me; Your rod and Your staff, they comfort me. You prepare a table before me in the presence of my enemies. You anoint my head with oil; my cup overflows. Surely goodness and mercy will follow me all the days of my life, and I will dwell in the house of the LORD forever.',
    displayTitle: 'Psalm 23',
  ),
  const ChapterInfo(
    bookCode: '1PE',
    bookName: '1 Peter',
    chapterNumber: 5,
    audioStreamUrl: '',
    textContent:
        'Casting all your anxieties on him, because he cares for you. Be sober-minded; be watchful. Your adversary the devil prowls around like a roaring lion, seeking someone to devour. Resist him, firm in your faith, knowing that the same kinds of suffering are being experienced by your brotherhood throughout the world.',
    displayTitle: '1 Peter 5:7–9',
  ),
];
