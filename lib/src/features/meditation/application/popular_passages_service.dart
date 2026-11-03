import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/popular_passage.dart';

final popularPassagesServiceProvider = Provider<PopularPassagesService>((ref) {
  return PopularPassagesService();
});

class PopularPassagesService {
  final List<PopularPassage> _passages;

  PopularPassagesService({List<PopularPassage>? passages})
      : _passages = passages ?? kCuratedPopularPassages;

  List<PopularPassage> getPopularPassages({
    PopularTimeframe timeframe = PopularTimeframe.thisWeek,
    PopularSortBy sortBy = PopularSortBy.byMeditators,
  }) {
    final list = List<PopularPassage>.from(_passages);
    list.sort((a, b) {
      if (sortBy == PopularSortBy.byMeditators) {
        final cmp = b.getMeditators(timeframe).compareTo(a.getMeditators(timeframe));
        if (cmp != 0) return cmp;
        return b.getLoops(timeframe).compareTo(a.getLoops(timeframe));
      } else {
        final cmp = b.getLoops(timeframe).compareTo(a.getLoops(timeframe));
        if (cmp != 0) return cmp;
        return b.getMeditators(timeframe).compareTo(a.getMeditators(timeframe));
      }
    });
    return list;
  }
}
