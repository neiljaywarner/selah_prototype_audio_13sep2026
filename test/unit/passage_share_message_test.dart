import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/constants/api_constants.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/constants/bible_canon.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/constants/protestant_verse_counts.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/passage_share_launcher.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share_message.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// Short stand-in wording. These tests must not store real ESV text.
const _fixture = 'Placeholder words for the selected range.';
const _tail = 'zzzz-end-marker';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Protestant verse counts', () {
    test('cover every book and the 31102-verse canon', () {
      expect(kProtestantVerseCounts, hasLength(BibleCanon.books.length));
      for (final book in BibleCanon.books) {
        expect(
          kProtestantVerseCounts[book.code],
          greaterThan(0),
          reason: book.code,
        );
      }
      final total = kProtestantVerseCounts.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );
      expect(total, 31102);
      expect(kProtestantVerseCounts['2JN'], 13);
      expect(kProtestantVerseCounts['3JN'], 14);
      expect(kProtestantVerseCounts['OBA'], 21);
    });
  });

  group('Share message happy path', () {
    test(
      'ESV share includes the loaded words, reference, mark, notice, and link',
      () {
        final payload = PassageShareLink.tryPayload(
          reference: 'John 16:32-33',
          translation: BibleTranslation.esv,
          verseText: '$_fixture (ESV)',
          attribution: BibleTranslation.esv.shortAttribution,
        );

        expect(payload, isNotNull);
        expect(payload!.includesVerseText, isTrue);
        expect(payload.reference, 'John 16:32-33');
        expect(payload.url, 'https://selahword.web.app/?ref=John+16:32-33');
        expect(
          payload.message,
          'Listen to John 16:32-33 in Selah\n'
          '\n'
          '$_fixture\n'
          '(ESV)\n'
          '\n'
          '${payload.url}\n'
          '\n'
          '$kEsvCopyrightNotice',
        );
        expect(payload.message, isNot(contains('$_fixture (ESV)')));
        expect(payload.url, isNot(contains(_fixture)));
        expect(payload.message, isNot(contains('test-esv-key')));
        expect(payload.message, isNot(contains('Authorization')));
      },
    );

    test(
      'BSB share uses the public-domain credit and not the Crossway notice',
      () {
        final payload = PassageShareLink.tryPayload(
          reference: '1 Cor 13:4-7',
          translation: BibleTranslation.bsb,
          verseText: _fixture,
          attribution: BibleTranslation.bsb.shortAttribution,
        );

        expect(payload!.includesVerseText, isTrue);
        expect(payload.message, contains(_fixture));
        expect(payload.message, contains('(BSB)'));
        expect(
          payload.message,
          contains('Public Domain · Narrator: Barry Hays'),
        );
        expect(
          payload.message,
          contains('https://selahword.web.app/?ref=1+Cor+13:4-7'),
        );
        expect(payload.message, isNot(contains('Crossway')));
        expect(payload.message, isNot(contains(kEsvCopyrightNotice)));
      },
    );

    test('WEB share is marked WEB with its own credit', () {
      final payload = PassageShareLink.tryPayload(
        reference: 'John 16:32-33',
        translation: BibleTranslation.web,
        verseText: _fixture,
        attribution: BibleTranslation.web.shortAttribution,
      );

      expect(payload!.includesVerseText, isTrue);
      expect(payload.message, contains(_fixture));
      expect(payload.message, contains('(WEB)'));
      expect(payload.message, contains(BibleTranslation.web.shortAttribution));
      expect(payload.message, isNot(contains('Barry Hays')));
      expect(payload.message, isNot(contains('Crossway')));
    });
  });

  group('Share message long-range guard', () {
    test('ESV omits a range that is half or more of the book and still shares the link', () {
      final allowed = PassageShareLink.tryPayload(
        reference: '2 John 1:1-6',
        translation: BibleTranslation.esv,
        verseText: _fixture,
        attribution: BibleTranslation.esv.shortAttribution,
      );
      final overHalf = PassageShareLink.tryPayload(
        reference: '2 John 1:1-7',
        translation: BibleTranslation.esv,
        verseText: _fixture,
        attribution: BibleTranslation.esv.shortAttribution,
      );
      final wholeBook = PassageShareLink.tryPayload(
        reference: '2 John 1:1-13',
        translation: BibleTranslation.esv,
        verseText: _fixture,
        attribution: BibleTranslation.esv.shortAttribution,
      );

      expect(allowed!.includesVerseText, isTrue);
      expect(allowed.message, contains(_fixture));
      expect(overHalf!.includesVerseText, isFalse);
      expect(overHalf.message, isNot(contains(_fixture)));
      expect(overHalf.message, isNot(contains('…')));
      expect(overHalf.url, 'https://selahword.web.app/?ref=2+John+1:1-7');
      expect(overHalf.message, contains(overHalf.url));
      expect(overHalf.message, contains('2 John 1:1-7'));
      expect(overHalf.message, contains(BibleTranslation.esv.shortAttribution));
      expect(wholeBook!.includesVerseText, isFalse);
      expect(wholeBook.message, isNot(contains(_fixture)));
      expect(wholeBook.message, contains(wholeBook.url));
    });

    test('ESV omits a quote past the character budget instead of changing the words', () {
      final long = '${'alpha ' * 400}$_tail';
      expect(long.length, greaterThan(kShareScriptureCharacterBudget));

      final payload = PassageShareLink.tryPayload(
        reference: 'John 3:16',
        translation: BibleTranslation.esv,
        verseText: '$long (ESV)',
        attribution: BibleTranslation.esv.shortAttribution,
      );

      expect(payload!.includesVerseText, isFalse);
      expect(payload.message, isNot(contains(_tail)));
      expect(payload.message, isNot(contains('alpha alpha')));
      expect(payload.message, isNot(contains('…')));
      expect(payload.message, contains(payload.url));
      expect(payload.message, contains('John 3:16'));
    });

    test(
      'BSB keeps a whole short book and truncates only an oversized quote',
      () {
        final wholeBook = PassageShareLink.tryPayload(
          reference: '2 John 1:1-13',
          translation: BibleTranslation.bsb,
          verseText: _fixture,
          attribution: BibleTranslation.bsb.shortAttribution,
        );
        final long = '${'alpha ' * 400}$_tail';
        final truncated = PassageShareLink.tryPayload(
          reference: 'Psalm 119:1-20',
          translation: BibleTranslation.bsb,
          verseText: long,
          attribution: BibleTranslation.bsb.shortAttribution,
        );

        expect(wholeBook!.includesVerseText, isTrue);
        expect(wholeBook.message, contains(_fixture));
        expect(wholeBook.message, contains('(BSB)'));
        expect(wholeBook.message, isNot(contains('Crossway')));
        expect(truncated!.includesVerseText, isTrue);
        expect(truncated.message, contains('…'));
        expect(truncated.message, contains('(BSB)'));
        expect(truncated.message, isNot(contains(_tail)));
        expect(truncated.message, contains(truncated.url));
        expect(truncated.url, isNot(contains('alpha')));
      },
    );

    test('a 501-verse quotation is over the Crossway request cap', () {
      expect(
        PassageShareMessage.esvRangeMayBeQuoted(
          verseSpan: 501,
          bookVerses: 2461,
          bookChapters: 150,
        ),
        isFalse,
      );
      expect(
        PassageShareMessage.esvRangeMayBeQuoted(
          verseSpan: 6,
          bookVerses: 13,
          bookChapters: 1,
        ),
        isTrue,
      );
      expect(
        PassageShareMessage.esvRangeMayBeQuoted(
          verseSpan: null,
          bookVerses: 21,
          bookChapters: 1,
        ),
        isFalse,
      );
    });
  });

  group('Share message when the words are unavailable', () {
    test(
      'null, blank, and player placeholders share the reference and link',
      () {
        const reference = 'John 3:16';
        const url = 'https://selahword.web.app/?ref=John+3:16';
        final placeholders = <String?>[
          null,
          '',
          '   ',
          'Press play to listen to John 3:16.',
          'This link does not open a passage. Search for another reference, or ask for a new link.',
          'John Chapter 3.\n\n"In the beginning was the Word, and the Word was with God, and the Word was God."',
        ];

        for (final verseText in placeholders) {
          final payload = PassageShareLink.tryPayload(
            reference: reference,
            translation: BibleTranslation.esv,
            verseText: verseText,
            attribution: BibleTranslation.esv.shortAttribution,
          );
          expect(payload, isNotNull, reason: '$verseText');
          expect(payload!.includesVerseText, isFalse, reason: '$verseText');
          expect(payload.url, url);
          expect(payload.message, contains('Listen to John 3:16 in Selah'));
          expect(payload.message, contains(url));
          expect(
            payload.message,
            contains(BibleTranslation.esv.shortAttribution),
          );
          expect(payload.message, isNot(contains('Press play')));
          expect(
            payload.message,
            isNot(contains('In the beginning was the Word')),
          );
          expect(payload.message, isNot(contains(_fixture)));
        }
      },
    );

    test('NIV never pastes verse text', () {
      final payload = PassageShareLink.tryPayload(
        reference: '1 Cor 13:4-7',
        translation: BibleTranslation.niv,
        verseText: _fixture,
        attribution: BibleTranslation.niv.shortAttribution,
      );

      expect(payload!.includesVerseText, isFalse);
      expect(payload.message, isNot(contains(_fixture)));
      expect(payload.message, contains(BibleTranslation.niv.shortAttribution));
      expect(payload.message, contains(payload.url));
      expect(payload.message, isNot(contains('Crossway')));
    });

    test('on-screen words are quoted only for the passage and translation that loaded them', () {
      expect(
        PassageShareMessage.textReadyToShare(
          translation: BibleTranslation.bsb,
          onScreenText: _fixture,
          samePassage: true,
        ),
        _fixture,
      );
      expect(
        PassageShareMessage.textReadyToShare(
          translation: BibleTranslation.esv,
          onScreenText: _fixture,
          samePassage: true,
        ),
        isNull,
      );
      expect(
        PassageShareMessage.textReadyToShare(
          translation: BibleTranslation.esv,
          onScreenText: '$_fixture (ESV)',
          samePassage: true,
        ),
        '$_fixture (ESV)',
      );
      expect(
        PassageShareMessage.textReadyToShare(
          translation: BibleTranslation.web,
          onScreenText: _fixture,
          samePassage: true,
          bsbText: _fixture,
          webText: 'Different public-domain wording.',
        ),
        isNull,
      );
      expect(
        PassageShareMessage.textReadyToShare(
          translation: BibleTranslation.niv,
          onScreenText: '$_fixture (ESV)',
          samePassage: true,
        ),
        isNull,
      );
      expect(
        PassageShareMessage.textReadyToShare(
          translation: BibleTranslation.bsb,
          onScreenText: _fixture,
          samePassage: false,
        ),
        isNull,
      );
      expect(
        PassageShareMessage.textReadyToShare(
          translation: BibleTranslation.esv,
          onScreenText: '$_fixture (ESV)',
          samePassage: true,
        ),
        '$_fixture (ESV)',
        reason: 'audio still buffering does not hide words already on screen',
      );
      expect(
        PassageShareMessage.textReadyToShare(
          translation: BibleTranslation.bsb,
          onScreenText: 'Press play to listen to John 3:16.',
          samePassage: true,
        ),
        isNull,
      );
    });

    test('BSB and WEB do not adopt wording marked as ESV', () {
      const esvMarked = '$_fixture (ESV)';
      for (final translation in [BibleTranslation.bsb, BibleTranslation.web]) {
        expect(
          PassageShareMessage.textReadyToShare(
            translation: translation,
            onScreenText: esvMarked,
            samePassage: true,
          ),
          isNull,
          reason: translation.code,
        );
        final payload = PassageShareLink.tryPayload(
          reference: 'John 16:32-33',
          translation: translation,
          verseText: esvMarked,
          attribution: translation.shortAttribution,
        );
        expect(payload!.includesVerseText, isFalse, reason: translation.code);
        expect(payload.message, isNot(contains(_fixture)), reason: translation.code);
        expect(payload.message, isNot(contains('(ESV)')), reason: translation.code);
        expect(payload.message, contains(payload.url));
      }
    });
  });

  group('Share sheet receives the built message', () {
    late _CapturingSharePlatform platform;
    late PlatformPassageShareLauncher launcher;
    late String? copied;

    setUp(() {
      platform = _CapturingSharePlatform();
      launcher = PlatformPassageShareLauncher(
        sharePlus: SharePlus.custom(platform),
      );
      copied = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              final args = call.arguments;
              if (args is Map && args['text'] is String) {
                copied = args['text'] as String;
              }
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test(
      'happy path hands the quotation to the sheet and copies only the link',
      () async {
        final payload = PassageShareLink.tryPayload(
          reference: 'John 16:32-33',
          translation: BibleTranslation.esv,
          verseText: _fixture,
          attribution: BibleTranslation.esv.shortAttribution,
        )!;

        await launcher.share(payload);

        expect(platform.last?.text, payload.message);
        expect(platform.last!.text, contains(_fixture));
        expect(platform.last!.text, contains('(ESV)'));
        expect(platform.last!.text, contains(kEsvCopyrightNotice));
        expect(platform.last!.subject, 'Selah · John 16:32-33');
        expect(copied, payload.url);
        expect(copied, isNot(contains(_fixture)));
      },
    );

    test(
      'long ESV range hands over the reference and link without the body',
      () async {
        final payload = PassageShareLink.tryPayload(
          reference: '2 John 1:1-13',
          translation: BibleTranslation.esv,
          verseText: _fixture,
          attribution: BibleTranslation.esv.shortAttribution,
        )!;

        await launcher.share(payload);

        expect(platform.last?.text, payload.message);
        expect(platform.last!.text, isNot(contains(_fixture)));
        expect(platform.last!.text, contains(payload.url));
        expect(copied, payload.url);
      },
    );

    test('missing words hand over the reference and link', () async {
      final payload = PassageShareLink.tryPayload(
        reference: 'John 3:16',
        translation: BibleTranslation.bsb,
        verseText: 'Press play to listen to John 3:16.',
        attribution: BibleTranslation.bsb.shortAttribution,
      )!;

      await launcher.share(payload);

      expect(platform.last?.text, isNot(contains('Press play')));
      expect(platform.last!.text, contains('John 3:16'));
      expect(platform.last!.text, contains(payload.url));
      expect(copied, payload.url);
    });
  });
}

class _CapturingSharePlatform extends SharePlatform {
  ShareParams? last;

  @override
  Future<ShareResult> share(ShareParams params) async {
    last = params;
    return ShareResult.unavailable;
  }
}
