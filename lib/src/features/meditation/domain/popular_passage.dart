enum PopularTimeframe {
  thisWeek,
  thisMonth,
  allTime,
}

enum PopularSortBy {
  byMeditators,
  byLoops,
}

class PopularPassageStats {
  final int meditators;
  final int loops;

  const PopularPassageStats({
    required this.meditators,
    required this.loops,
  });

  Map<String, dynamic> toJson() => {
        'meditators': meditators,
        'loops': loops,
      };

  factory PopularPassageStats.fromJson(Map<String, dynamic> json) =>
      PopularPassageStats(
        meditators: (json['meditators'] as num?)?.toInt() ?? 0,
        loops: (json['loops'] as num?)?.toInt() ?? 0,
      );
}

class PopularPassage {
  final String reference;
  final String title;
  final String bookCode;
  final int chapterNumber;
  final int? startVerse;
  final int? endVerse;
  final String theme;
  final Map<PopularTimeframe, PopularPassageStats> stats;

  const PopularPassage({
    required this.reference,
    required this.title,
    required this.bookCode,
    required this.chapterNumber,
    this.startVerse,
    this.endVerse,
    required this.theme,
    required this.stats,
  });

  int getMeditators(PopularTimeframe tf) => stats[tf]?.meditators ?? 0;
  int getLoops(PopularTimeframe tf) => stats[tf]?.loops ?? 0;

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'title': title,
        'bookCode': bookCode,
        'chapterNumber': chapterNumber,
        'startVerse': startVerse,
        'endVerse': endVerse,
        'theme': theme,
        'stats': {
          'thisWeek': stats[PopularTimeframe.thisWeek]?.toJson(),
          'thisMonth': stats[PopularTimeframe.thisMonth]?.toJson(),
          'allTime': stats[PopularTimeframe.allTime]?.toJson(),
        },
      };

  factory PopularPassage.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as Map<String, dynamic>? ?? {};
    return PopularPassage(
      reference: json['reference'] as String,
      title: json['title'] as String,
      bookCode: json['bookCode'] as String,
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      startVerse: (json['startVerse'] as num?)?.toInt(),
      endVerse: (json['endVerse'] as num?)?.toInt(),
      theme: json['theme'] as String? ?? 'Meditation',
      stats: {
        PopularTimeframe.thisWeek: rawStats['thisWeek'] != null
            ? PopularPassageStats.fromJson(rawStats['thisWeek'] as Map<String, dynamic>)
            : const PopularPassageStats(meditators: 0, loops: 0),
        PopularTimeframe.thisMonth: rawStats['thisMonth'] != null
            ? PopularPassageStats.fromJson(rawStats['thisMonth'] as Map<String, dynamic>)
            : const PopularPassageStats(meditators: 0, loops: 0),
        PopularTimeframe.allTime: rawStats['allTime'] != null
            ? PopularPassageStats.fromJson(rawStats['allTime'] as Map<String, dynamic>)
            : const PopularPassageStats(meditators: 0, loops: 0),
      },
    );
  }
}

/// Curated contemplative community favorites across All-Time, Month, and Week.
final List<PopularPassage> kCuratedPopularPassages = [
  const PopularPassage(
    reference: '1 Corinthians 13:4–7',
    title: 'Love is Patient, Love is Kind',
    bookCode: '1CO',
    chapterNumber: 13,
    startVerse: 4,
    endVerse: 7,
    theme: 'Love',
    stats: {
      PopularTimeframe.thisWeek: PopularPassageStats(meditators: 1420, loops: 8920),
      PopularTimeframe.thisMonth: PopularPassageStats(meditators: 5890, loops: 37400),
      PopularTimeframe.allTime: PopularPassageStats(meditators: 24300, loops: 154200),
    },
  ),
  const PopularPassage(
    reference: 'Psalm 23',
    title: 'The Lord is My Shepherd',
    bookCode: 'PSA',
    chapterNumber: 23,
    startVerse: 1,
    endVerse: 6,
    theme: 'Comfort',
    stats: {
      PopularTimeframe.thisWeek: PopularPassageStats(meditators: 1280, loops: 7650),
      PopularTimeframe.thisMonth: PopularPassageStats(meditators: 5120, loops: 31800),
      PopularTimeframe.allTime: PopularPassageStats(meditators: 28400, loops: 178000),
    },
  ),
  const PopularPassage(
    reference: 'Matthew 11:28–30',
    title: 'Come to Me and I Will Give You Rest',
    bookCode: 'MAT',
    chapterNumber: 11,
    startVerse: 28,
    endVerse: 30,
    theme: 'Rest',
    stats: {
      PopularTimeframe.thisWeek: PopularPassageStats(meditators: 1040, loops: 6400),
      PopularTimeframe.thisMonth: PopularPassageStats(meditators: 4210, loops: 26500),
      PopularTimeframe.allTime: PopularPassageStats(meditators: 19800, loops: 122400),
    },
  ),
  const PopularPassage(
    reference: 'Philippians 4:6–7',
    title: 'The Peace of God Surpassing Understanding',
    bookCode: 'PHP',
    chapterNumber: 4,
    startVerse: 6,
    endVerse: 7,
    theme: 'Peace',
    stats: {
      PopularTimeframe.thisWeek: PopularPassageStats(meditators: 890, loops: 5100),
      PopularTimeframe.thisMonth: PopularPassageStats(meditators: 3950, loops: 22800),
      PopularTimeframe.allTime: PopularPassageStats(meditators: 18100, loops: 109200),
    },
  ),
  const PopularPassage(
    reference: 'Isaiah 40:28–31',
    title: 'They Shall Mount Up with Wings Like Eagles',
    bookCode: 'ISA',
    chapterNumber: 40,
    startVerse: 28,
    endVerse: 31,
    theme: 'Strength',
    stats: {
      PopularTimeframe.thisWeek: PopularPassageStats(meditators: 740, loops: 4200),
      PopularTimeframe.thisMonth: PopularPassageStats(meditators: 3100, loops: 18500),
      PopularTimeframe.allTime: PopularPassageStats(meditators: 15300, loops: 92400),
    },
  ),
  const PopularPassage(
    reference: 'Romans 8:38–39',
    title: 'Nothing Can Separate Us from God\'s Love',
    bookCode: 'ROM',
    chapterNumber: 8,
    startVerse: 38,
    endVerse: 39,
    theme: 'Security',
    stats: {
      PopularTimeframe.thisWeek: PopularPassageStats(meditators: 680, loops: 3900),
      PopularTimeframe.thisMonth: PopularPassageStats(meditators: 2850, loops: 16700),
      PopularTimeframe.allTime: PopularPassageStats(meditators: 14200, loops: 84600),
    },
  ),
  const PopularPassage(
    reference: 'John 15:4–5',
    title: 'Abide in Me, as I Also Abide in You',
    bookCode: 'JHN',
    chapterNumber: 15,
    startVerse: 4,
    endVerse: 5,
    theme: 'Stillness',
    stats: {
      PopularTimeframe.thisWeek: PopularPassageStats(meditators: 610, loops: 3600),
      PopularTimeframe.thisMonth: PopularPassageStats(meditators: 2540, loops: 15100),
      PopularTimeframe.allTime: PopularPassageStats(meditators: 12900, loops: 78300),
    },
  ),
  const PopularPassage(
    reference: 'Lamentations 3:22–24',
    title: 'His Mercies Are New Every Morning',
    bookCode: 'LAM',
    chapterNumber: 3,
    startVerse: 22,
    endVerse: 24,
    theme: 'Morning',
    stats: {
      PopularTimeframe.thisWeek: PopularPassageStats(meditators: 520, loops: 2980),
      PopularTimeframe.thisMonth: PopularPassageStats(meditators: 2180, loops: 12900),
      PopularTimeframe.allTime: PopularPassageStats(meditators: 11400, loops: 67500),
    },
  ),
];
