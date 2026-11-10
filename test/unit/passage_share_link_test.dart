import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/core/constants/bible_canon.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/application/passage_share_launcher.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/bible_translation.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/chapter_info.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_share.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const loveSnippet = 'Love is patient, love is kind';
  const hostedUrl = 'https://selahword.web.app/?ref=1+Cor+13:4-7';

  group('PassageShareLink', () {
    test('encodes 1 Cor 13:4-7 as a selahword.web.app reference link', () {
      expect(PassageShareLink.buildUrl('1 Cor 13:4-7'), hostedUrl);
      expect(PassageShareLink.buildUrl('1 Cor 13:4–7'), hostedUrl);
      expect(PassageShareLink.buildUrl('1 Cor 13:4-7'), isNot(contains('github.io')));
    });

    test('keeps the colon readable and uses plus for spaces', () {
      final url = PassageShareLink.buildUrl('1 Cor 13:4-7');
      expect(url, contains('ref=1+Cor+13:4-7'));
      expect(url, isNot(contains('%3A')));
      expect(url, isNot(contains(loveSnippet)));
    });

    test('uses the page origin when the app is already on the web', () {
      final preview = PassageShareLink.buildUrl(
        '1 Cor 13:4-7',
        page: Uri.parse('https://selahword--pr-240-abc.web.app/index.html'),
      );
      expect(preview, 'https://selahword--pr-240-abc.web.app/?ref=1+Cor+13:4-7');

      final pages = PassageShareLink.buildUrl(
        '1 Cor 13:4-7',
        page: Uri.parse(
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/index.html?debug=1',
        ),
      );
      expect(pages,
          'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=1+Cor+13:4-7');
    });

    test('parses the share token, a full URL, and percent-encoding', () {
      for (final raw in [
        '1 Cor 13:4-7',
        '1+Cor+13:4-7',
        '1%20Cor%2013:4-7',
        hostedUrl,
        'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=1+Cor+13:4-7',
        '1 Corinthians 13:4-7',
      ]) {
        final parsed = PassageShareLink.tryParse(raw);
        expect(parsed, isNotNull, reason: raw);
        expect(parsed!.canonical, '1 Cor 13:4-7');
        expect(parsed.book.code, '1CO');
        expect(parsed.chapter, 13);
        expect(parsed.startVerse, 4);
        expect(parsed.endVerse, 7);
      }
    });

    test('payload contains the reference and short attribution, not the verse', () {
      final verse = kFeaturedChapters.first.textContent;
      expect(verse, contains(loveSnippet));

      final payload = PassageShareLink.tryPayload(
        reference: kFeaturedChapters.first.reference,
        attribution: BibleTranslation.esv.shortAttribution,
      );

      expect(payload, isNotNull);
      expect(payload!.reference, '1 Cor 13:4-7');
      expect(payload.url, hostedUrl);
      expect(payload.message, contains('Listen to 1 Cor 13:4-7 in Selah'));
      expect(payload.message, contains(hostedUrl));
      expect(payload.message, contains(BibleTranslation.esv.shortAttribution));
      expect(payload.message, isNot(contains(loveSnippet)));
      expect(payload.message, isNot(contains(verse)));
      expect(payload.url, isNot(contains(verse)));
    });

    test('drops a long copyright dump instead of pasting scripture', () {
      final payload = PassageShareLink.tryPayload(
        reference: '1 Cor 13:4-7',
        attribution: '${BibleTranslation.esv.copyright} $loveSnippet',
      );
      expect(payload!.attribution, isNull);
      expect(payload.message, isNot(contains(loveSnippet)));
      expect(payload.message, isNot(contains('Crossway')));
    });

    test('reads exact-ref JSON from My Passages without the label body', () {
      final stored = '{"q":"1 Cor 13:4-7","l":"$loveSnippet. It does not envy."}';
      final items = PassageShareLink.itemsFromSaved([stored, 'not a passage']);
      expect(items, hasLength(1));
      expect(items.single.passage.canonical, '1 Cor 13:4-7');

      final payload = PassageShareLink.tryPayload(reference: items.single.passage.canonical);
      expect(payload!.message, isNot(contains(loveSnippet)));
    });

    test('unknown, reversed, and out-of-range references do not parse', () {
      expect(PassageShareLink.tryParse('NotABook 99:1'), isNull);
      expect(PassageShareLink.tryParse('1 Cor 99:1'), isNull);
      expect(PassageShareLink.tryParse('1 Cor 13:7-4'), isNull);
      expect(PassageShareLink.tryParse('1 Cor 13:0-2'), isNull);
      expect(PassageShareLink.tryParse(''), isNull);
      expect(PassageShareLink.tryParse('https://example.com/listen'), isNull);

      final message = PassageShareLink.friendlyError(
        'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=NotABook+99:1',
      );
      expect(message, contains("Couldn't open that link"));
      expect(message, contains('NotABook 99:1'));
      expect(message, isNot(contains(loveSnippet)));
    });

    test('every book round-trips from its full name and its share label', () {
      for (final book in BibleCanon.books) {
        final fromName = PassageShareLink.tryParse('${book.name} 1');
        expect(fromName, isNotNull, reason: book.name);
        expect(fromName!.book.code, book.code, reason: book.name);
        expect(fromName.chapter, 1);

        final payload = PassageShareLink.tryPayload(reference: '${book.name} 1');
        expect(payload, isNotNull, reason: book.name);
        expect(payload!.reference, fromName.canonical);

        final opened = PassageShareLink.tryParse(payload.url);
        expect(opened?.canonical, fromName.canonical, reason: payload.url);

        final fromLabel = PassageShareLink.tryParse(fromName.canonical);
        expect(fromLabel?.canonical, fromName.canonical, reason: fromName.canonical);
        expect(fromLabel?.book.code, book.code);
      }
    });
  });

  group('PlatformPassageShareLauncher', () {
    test('copies the link and hands the reference-only message to the share sheet', () async {
      final platform = _CapturingSharePlatform();
      final launcher = PlatformPassageShareLauncher(sharePlus: SharePlus.custom(platform));
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments;
            if (args is Map && args['text'] is String) copied = args['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      final payload = PassageShareLink.tryPayload(
        reference: '1 Cor 13:4-7',
        attribution: BibleTranslation.esv.shortAttribution,
      )!;
      await launcher.share(payload);

      expect(copied, payload.url);
      expect(copied, isNot(contains(loveSnippet)));
      expect(platform.last, isNotNull);
      expect(platform.last!.text, payload.message);
      expect(platform.last!.text, contains('1+Cor+13:4-7'));
      expect(platform.last!.text, isNot(contains(loveSnippet)));
      expect(platform.last!.subject, 'Selah · 1 Cor 13:4-7');
      expect(platform.last!.uri, isNull);
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
