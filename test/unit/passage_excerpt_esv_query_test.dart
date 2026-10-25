import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  test('curated 1 Cor 13:4-7 excerpt maps to four-verse ESV query', () {
    final excerpt = kCuratedExcerpts.first;
    expect(excerpt.toEsvPassageQuery(), '1 Cor 13:4-7');
  });

  test('featured chip display titles normalize for ESV', () {
    final featured = kFeaturedChapters.first;
    expect(esvPassageQueryFor(featured), '1 Cor 13:4-7');
  });

  test('custom excerpt without display title uses canonical book name', () {
    final excerpt = PassageExcerpt.customExcerpt(
      bookCode: 'JHN',
      chapterNumber: 11,
      startVerse: 35,
      endVerse: 35,
    )!;
    expect(excerpt.toEsvPassageQuery(), 'John 11:35');
  });
}
