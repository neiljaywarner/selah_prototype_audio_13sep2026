import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/popular_passage.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/popular_passages_service.dart';

void main() {
  group('PopularPassagesService Tests', () {
    late PopularPassagesService service;

    setUp(() {
      service = PopularPassagesService();
    });

    test('returns curated popular passages', () {
      final passages = service.getPopularPassages();
      expect(passages, isNotEmpty);
      expect(passages.any((p) => p.reference.contains('1 Corinthians 13')), isTrue);
      expect(passages.any((p) => p.reference.contains('Psalm 23')), isTrue);
    });

    test('sorts by meditators descending for thisWeek', () {
      final passages = service.getPopularPassages(
        timeframe: PopularTimeframe.thisWeek,
        sortBy: PopularSortBy.byMeditators,
      );

      for (int i = 0; i < passages.length - 1; i++) {
        final current = passages[i].getMeditators(PopularTimeframe.thisWeek);
        final next = passages[i + 1].getMeditators(PopularTimeframe.thisWeek);
        expect(current >= next, isTrue, reason: '$current should be >= $next');
      }
    });

    test('sorts by loops descending for allTime', () {
      final passages = service.getPopularPassages(
        timeframe: PopularTimeframe.allTime,
        sortBy: PopularSortBy.byLoops,
      );

      for (int i = 0; i < passages.length - 1; i++) {
        final current = passages[i].getLoops(PopularTimeframe.allTime);
        final next = passages[i + 1].getLoops(PopularTimeframe.allTime);
        expect(current >= next, isTrue, reason: '$current should be >= $next');
      }
    });

    test('serializes and deserializes PopularPassage and stats cleanly', () {
      final original = kCuratedPopularPassages.first;
      final json = original.toJson();
      final revived = PopularPassage.fromJson(json);

      expect(revived.reference, equals(original.reference));
      expect(revived.title, equals(original.title));
      expect(revived.theme, equals(original.theme));
      expect(
        revived.getMeditators(PopularTimeframe.thisWeek),
        equals(original.getMeditators(PopularTimeframe.thisWeek)),
      );
      expect(
        revived.getLoops(PopularTimeframe.allTime),
        equals(original.getLoops(PopularTimeframe.allTime)),
      );
    });
  });
}
