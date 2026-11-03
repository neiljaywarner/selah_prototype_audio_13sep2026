import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/esv/esv_api_client.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/saved_passage.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/preferences/user_preferences.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_excerpt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const psalmChapter = ChapterInfo(
    bookCode: 'PSA',
    bookName: 'Psalms',
    chapterNumber: 23,
    audioStreamUrl: '',
    textContent: 'The LORD is my shepherd',
    displayTitle: 'Psalm 23',
  );

  const loveExcerpt = PassageExcerpt(
    bookCode: '1CO',
    chapterNumber: 13,
    startVerse: 4,
    endVerse: 7,
    displayTitle: '1 Cor 13:4–7',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('canonicalize keeps a same-chapter range and a single verse intact', () {
    expect(PassageQuery.canonicalize('1 Cor 13:4-7'), '1 Cor 13:4-7');
    expect(PassageQuery.canonicalize('1 Cor 13:4 – 7'), '1 Cor 13:4-7');
    expect(PassageQuery.canonicalize('1 Cor 13:4–7'), '1 Cor 13:4-7');
    expect(PassageQuery.canonicalize('  John   11:35 '), 'John 11:35');
    expect(PassageQuery.canonicalize('Psalm 23:1-6'), 'Psalm 23:1-6');
    expect(PassageQuery.isVerseOrRange('John 11:35'), isTrue);
    expect(PassageQuery.isVerseOrRange('Psalm 23:1-6'), isTrue);
    expect(PassageQuery.isVerseOrRange('Psalm 23'), isFalse);
    expect(
      EsvApiClient.expandToSingleVerses('1 Cor 13:4-7'),
      ['1 Cor 13:4', '1 Cor 13:5', '1 Cor 13:6', '1 Cor 13:7'],
    );
    expect(
      EsvApiClient.expandToSingleVerses('1 Corinthians 13:4-7'),
      ['1 Corinthians 13:4', '1 Corinthians 13:5', '1 Corinthians 13:6', '1 Corinthians 13:7'],
    );
    expect(EsvApiClient.expandToSingleVerses('John 11:35'), ['John 11:35']);
    expect(
      EsvApiClient.expandToSingleVerses('Psalm 23:1-3'),
      ['Psalm 23:1', 'Psalm 23:2', 'Psalm 23:3'],
    );
    expect(EsvApiClient.expandToSingleVerses('Psalm 23:1-3'), isNot(contains('Psalm 23')));
  });

  test('typed range wins over the chapter currently on screen', () {
    expect(
      resolvePassageToSave(fieldText: '1 Cor 13:4-7', chapter: psalmChapter),
      '1 Cor 13:4-7',
    );
    expect(
      resolvePassageToSave(fieldText: '1 Cor 13:4 – 7', chapter: psalmChapter),
      '1 Cor 13:4-7',
    );
    expect(
      resolvePassageToSave(fieldText: 'John 11:35', chapter: psalmChapter),
      'John 11:35',
    );
    expect(
      resolvePassageToSave(fieldText: 'Psalm 23:1-6', chapter: psalmChapter),
      'Psalm 23:1-6',
    );
    expect(
      resolvePassageToSave(
        fieldText: '',
        chapter: psalmChapter,
        activeExcerpt: loveExcerpt,
      ),
      '1 Cor 13:4-7',
    );
    expect(
      resolvePassageToSave(fieldText: '', chapter: psalmChapter),
      'Psalm 23',
    );
  });

  test('save, reload, and the stored query still expand to the same verses', () async {
    final prefs = await SharedPreferences.getInstance();
    final writer = UserPreferences(prefs);

    final result = await writer.saveMyPassage(
      const SavedPassage(query: '1 Cor 13:4 – 7', label: '1 Cor 13:4 – 7'),
    );
    expect(result, SavePassageResult.saved);

    final reader = UserPreferences(prefs);
    expect(reader.myPassages, hasLength(1));
    expect(reader.myPassages.single.query, '1 Cor 13:4-7');
    expect(
      EsvApiClient.expandToSingleVerses(reader.myPassages.single.query),
      ['1 Cor 13:4', '1 Cor 13:5', '1 Cor 13:6', '1 Cor 13:7'],
    );

    await writer.saveMyPassage(const SavedPassage(query: 'John 11:35', label: 'John 11:35'));
    await writer.saveMyPassage(const SavedPassage(query: 'Psalm 23:1-3', label: 'Psalm 23:1-3'));
    final again = UserPreferences(prefs);
    expect(again.myPassages.map((p) => p.query).toList(), [
      'Psalm 23:1-3',
      'John 11:35',
      '1 Cor 13:4-7',
    ]);
    expect(EsvApiClient.expandToSingleVerses(again.myPassages.first.query), [
      'Psalm 23:1',
      'Psalm 23:2',
      'Psalm 23:3',
    ]);
  });

  test('rename keeps the replay query and remove drops only that passage', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = UserPreferences(prefs);
    await store.saveMyPassage(const SavedPassage(query: '1 Cor 13:4-7', label: '1 Cor 13:4-7'));
    await store.saveMyPassage(const SavedPassage(query: 'John 11:35', label: 'John 11:35'));

    expect(await store.renameMyPassage('1 Cor 13:4-7', '  Love passage  '), isTrue);
    expect(await store.renameMyPassage('1 Cor 13:4-7', '   '), isFalse);

    final renamed = UserPreferences(prefs).myPassages.firstWhere((p) => p.query == '1 Cor 13:4-7');
    expect(renamed.label, 'Love passage');
    expect(renamed.query, '1 Cor 13:4-7');

    await store.removeMyPassage('John 11:35');
    final left = UserPreferences(prefs).myPassages;
    expect(left.map((p) => p.query), ['1 Cor 13:4-7']);
  });

  test('a full My passages list refuses the next save instead of dropping one', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = UserPreferences(prefs);
    for (var i = 1; i <= UserPreferences.myPassagesCap; i++) {
      final saved = await store.saveMyPassage(
        SavedPassage(query: 'John 1:$i', label: 'John 1:$i'),
      );
      expect(saved, SavePassageResult.saved, reason: 'John 1:$i');
    }
    final overflow = await store.saveMyPassage(
      const SavedPassage(query: 'John 1:99', label: 'John 1:99'),
    );
    expect(overflow, SavePassageResult.full);

    final reloaded = UserPreferences(prefs);
    expect(reloaded.myPassages, hasLength(UserPreferences.myPassagesCap));
    expect(reloaded.myPassages.any((p) => p.query == 'John 1:99'), isFalse);
    expect(reloaded.myPassages.any((p) => p.query == 'John 1:1'), isTrue);
  });

  test('legacy recents migrate into My passages without losing a verse range', () async {
    SharedPreferences.setMockInitialValues({
      UserPreferences.savedChaptersKey: ['1 Cor 13:4–7', 'John 11:35'],
    });
    final prefs = await SharedPreferences.getInstance();
    final before = UserPreferences(prefs);
    expect(before.myPassages.map((p) => p.query).toList(), ['1 Cor 13:4-7', 'John 11:35']);
    expect(before.myPassages.first.label, '1 Cor 13:4–7');

    await before.migrateLegacySavedChapters();
    expect(prefs.containsKey(UserPreferences.myPassagesKey), isTrue);

    final after = UserPreferences(prefs);
    expect(after.myPassages.map((p) => p.query).toList(), ['1 Cor 13:4-7', 'John 11:35']);
    expect(
      EsvApiClient.expandToSingleVerses(after.myPassages.first.query),
      ['1 Cor 13:4', '1 Cor 13:5', '1 Cor 13:6', '1 Cor 13:7'],
    );
  });

  test('playing history does not evict a bookmark and is what last-played restores', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = UserPreferences(prefs);
    await store.saveMyPassage(const SavedPassage(query: '1 Cor 13:4-7', label: 'Love'));
    for (var i = 1; i <= 20; i++) {
      await store.recordRecent('Mark $i:1');
    }
    final reloaded = UserPreferences(prefs);
    expect(reloaded.myPassages.map((p) => p.query), ['1 Cor 13:4-7']);
    expect(reloaded.recentPassages, hasLength(UserPreferences.recentPassagesCap));
    expect(reloaded.recentPassages.first.query, 'Mark 20:1');
    expect(reloaded.lastPlayedQuery, 'Mark 20:1');
    expect(reloaded.myPassages.any((p) => p.query == 'Mark 20:1'), isFalse);
  });
}
