import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/saved_passage.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChapterInfo chapterOnly() => const ChapterInfo(
    bookCode: '1CO',
    bookName: '1 Corinthians',
    chapterNumber: 13,
    audioStreamUrl: '',
    textContent: '',
  );

  test('canonicalize keeps the verse range and drops unicode dashes', () {
    expect(PassageQuery.canonicalize('1 Cor 13:4 – 7'), '1 Cor 13:4-7');
    expect(PassageQuery.canonicalize('1 Cor 13:4–7'), '1 Cor 13:4-7');
  });

  test('a typed range is saved instead of the loaded chapter', () {
    final query = resolvePassageToSave(
      fieldText: '1 Cor 13:4-7',
      chapter: chapterOnly(),
      activeExcerpt: null,
    );
    expect(query, '1 Cor 13:4-7');
    expect(query.contains(':'), isTrue);
  });

  test('an active excerpt supplies the range when the field is blank', () {
    final query = resolvePassageToSave(
      fieldText: 'love',
      chapter: chapterOnly(),
      activeExcerpt: PassageExcerpt.customExcerpt(
        bookCode: '1CO',
        chapterNumber: 13,
        startVerse: 4,
        endVerse: 7,
        displayTitle: '1 Cor 13:4-7',
      ),
    );
    expect(query, '1 Cor 13:4-7');
  });

  test('My passages keeps the exact query across a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = UserPreferences(prefs);

    final result = await store.saveMyPassage(
      const SavedPassage(query: '1 Cor 13:4–7', label: '1 Cor 13:4–7'),
    );
    expect(result, SavePassageResult.saved);

    final reloaded = UserPreferences(await SharedPreferences.getInstance());
    expect(reloaded.myPassages.single.query, '1 Cor 13:4-7');
    expect(reloaded.myPassages.single.label, '1 Cor 13:4–7');
  });

  test('legacy saved chapters become My passages once', () async {
    SharedPreferences.setMockInitialValues({
      UserPreferences.savedChaptersKey: ['Psalm 23', '1 Cor 13:4-7'],
    });
    final store = UserPreferences(await SharedPreferences.getInstance());
    expect(store.myPassages.map((p) => p.query), ['Psalm 23', '1 Cor 13:4-7']);

    await store.migrateLegacySavedChapters();
    await store.saveMyPassage(
      const SavedPassage(query: 'John 3:16', label: 'John 3:16'),
    );
    final queries = store.myPassages.map((p) => p.query).toList();
    expect(queries.first, 'John 3:16');
    expect(queries, contains('1 Cor 13:4-7'));
  });

  test(
    'a full list refuses another bookmark and keeps every saved range',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = UserPreferences(await SharedPreferences.getInstance());
      for (var i = 1; i <= UserPreferences.myPassagesCap; i++) {
        final saved = await store.saveMyPassage(
          SavedPassage(query: 'John 3:$i', label: 'John 3:$i'),
        );
        expect(saved, SavePassageResult.saved);
      }
      final refused = await store.saveMyPassage(
        const SavedPassage(query: '1 Cor 13:4-7', label: '1 Cor 13:4-7'),
      );
      expect(refused, SavePassageResult.full);
      expect(store.myPassages.length, UserPreferences.myPassagesCap);
      expect(
        store.myPassages.map((p) => p.query),
        isNot(contains('1 Cor 13:4-7')),
      );
    },
  );

  test('recent plays do not evict a bookmark', () async {
    SharedPreferences.setMockInitialValues({});
    final store = UserPreferences(await SharedPreferences.getInstance());
    await store.saveMyPassage(
      const SavedPassage(query: '1 Cor 13:4-7', label: '1 Cor 13:4-7'),
    );
    for (var i = 1; i <= UserPreferences.recentPassagesCap + 3; i++) {
      await store.recordRecent('Psalm $i');
    }
    expect(store.recentPassages.length, UserPreferences.recentPassagesCap);
    expect(store.myPassages.single.query, '1 Cor 13:4-7');
    expect(
      store.lastPlayedQuery,
      'Psalm ${UserPreferences.recentPassagesCap + 3}',
    );
  });

  test('renaming changes the label and leaves the replay query', () async {
    SharedPreferences.setMockInitialValues({});
    final store = UserPreferences(await SharedPreferences.getInstance());
    await store.saveMyPassage(
      const SavedPassage(query: '1 Cor 13:4-7', label: '1 Cor 13:4-7'),
    );
    expect(await store.renameMyPassage('1 Cor 13:4-7', 'Love'), isTrue);
    expect(store.myPassages.single.query, '1 Cor 13:4-7');
    expect(store.myPassages.single.label, 'Love');
  });

  test('a failed write is not reported as saved', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = UserPreferences(prefs, (_, _) async => false);

    final result = await store.saveMyPassage(
      const SavedPassage(query: '1 Cor 13:4-7', label: '1 Cor 13:4-7'),
    );
    expect(result, SavePassageResult.unavailable);
    expect(store.myPassages, isEmpty);
    expect(await store.renameMyPassage('1 Cor 13:4-7', 'Love'), isFalse);
  });
}
