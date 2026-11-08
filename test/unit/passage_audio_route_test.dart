import 'package:flutter_test/flutter_test.dart';
import 'package:selah_prototype_audio_13sep2026/src/features/meditation/domain/passage_audio_route.dart';

void main() {
  group('decidePassageAudio', () {
    test('ESV plays passage audio and does not speak', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: true,
            translationHasNarrator: true,
            hasBundledChapterAudio: false,
            hasChapterStream: false,
            requestedStart: 5,
            requestedEnd: 7,
            curatedStart: 1,
            curatedEnd: 2,
          ),
        ),
        PassageAudioDecision.playEsvPassage,
      );
    });

    test('ESV audio failure stays silent until a read-aloud was confirmed', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: true,
            esvAudioFailed: true,
            translationHasNarrator: true,
            hasBundledChapterAudio: true,
            hasChapterStream: false,
            requestedStart: 32,
            requestedEnd: 33,
          ),
        ),
        PassageAudioDecision.holdUnaligned,
      );
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: true,
            esvAudioFailed: true,
            readAloudConfirmed: true,
            translationHasNarrator: true,
            hasBundledChapterAudio: false,
            hasChapterStream: false,
            requestedStart: 32,
            requestedEnd: 33,
          ),
        ),
        PassageAudioDecision.speakWithTts,
      );
    });

    test('Psalm 62:5-7 asks before a read-aloud and does not play 62:1-2', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: true,
            hasChapterStream: false,
            requestedStart: 5,
            requestedEnd: 7,
            curatedStart: 1,
            curatedEnd: 2,
            clipCoversRequestedRange: false,
          ),
        ),
        PassageAudioDecision.askBeforeReadAloud,
      );
    });

    test('Psalm 62:5-7 speaks only after the listener confirms', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            readAloudConfirmed: true,
            translationHasNarrator: true,
            hasBundledChapterAudio: true,
            hasChapterStream: false,
            requestedStart: 5,
            requestedEnd: 7,
            curatedStart: 1,
            curatedEnd: 2,
            clipCoversRequestedRange: false,
          ),
        ),
        PassageAudioDecision.speakWithTts,
      );
    });

    test('Psalm 62:1-2 plays the bundled narrator clip', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: true,
            hasChapterStream: false,
            requestedStart: 1,
            requestedEnd: 2,
            curatedStart: 1,
            curatedEnd: 2,
            clipCoversRequestedRange: true,
          ),
        ),
        PassageAudioDecision.playNarratorClip,
      );
    });

    test('curated bundled audio still plays when timestamps are missing', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: true,
            hasChapterStream: false,
            requestedStart: 1,
            requestedEnd: 2,
            curatedStart: 1,
            curatedEnd: 2,
            clipCoversRequestedRange: false,
          ),
        ),
        PassageAudioDecision.playNarratorChapter,
      );
    });

    test(
      '1 Cor 13:8-13 does not play the bundled 13:4-7 file or start TTS',
      () {
        expect(
          decidePassageAudio(
            const PassageAudioSituation(
              esvMode: false,
              translationHasNarrator: true,
              hasBundledChapterAudio: true,
              hasChapterStream: true,
              requestedStart: 8,
              requestedEnd: 13,
              curatedStart: 4,
              curatedEnd: 7,
              clipCoversRequestedRange: false,
            ),
          ),
          PassageAudioDecision.askBeforeReadAloud,
        );
      },
    );

    test('1 Cor 13:4-7 clips the bundled narrator', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: true,
            hasChapterStream: false,
            requestedStart: 4,
            requestedEnd: 7,
            curatedStart: 4,
            curatedEnd: 7,
            clipCoversRequestedRange: true,
          ),
        ),
        PassageAudioDecision.playNarratorClip,
      );
    });

    test('a chapter stream that cannot be clipped does not start TTS', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: false,
            hasChapterStream: true,
            requestedStart: 32,
            requestedEnd: 33,
            clipCoversRequestedRange: false,
          ),
        ),
        PassageAudioDecision.askBeforeReadAloud,
      );
    });

    test('a covered range on a chapter stream is clipped', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: false,
            hasChapterStream: true,
            requestedStart: 32,
            requestedEnd: 33,
            clipCoversRequestedRange: true,
          ),
        ),
        PassageAudioDecision.playNarratorClip,
      );
    });

    test('John 16 with no human audio asks before TTS', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: false,
            hasChapterStream: false,
            requestedStart: 32,
            requestedEnd: 33,
          ),
        ),
        PassageAudioDecision.askBeforeReadAloud,
      );
    });

    test('WEB Old Testament asks before TTS', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: false,
            hasBundledChapterAudio: false,
            hasChapterStream: false,
            requestedStart: 5,
            requestedEnd: 7,
            curatedStart: 1,
            curatedEnd: 2,
          ),
        ),
        PassageAudioDecision.askBeforeReadAloud,
      );
    });

    test('a whole chapter with a stream plays the narrator, not TTS', () {
      expect(
        decidePassageAudio(
          const PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: false,
            hasChapterStream: true,
          ),
        ),
        PassageAudioDecision.playNarratorChapter,
      );
    });

    test('BSB and WEB Psalm 62 share the unclippable-range decision', () {
      for (final bundled in [true, false]) {
        final decision = decidePassageAudio(
          PassageAudioSituation(
            esvMode: false,
            translationHasNarrator: true,
            hasBundledChapterAudio: bundled,
            hasChapterStream: !bundled,
            requestedStart: 5,
            requestedEnd: 7,
            curatedStart: 1,
            curatedEnd: 2,
            clipCoversRequestedRange: false,
          ),
        );
        expect(decision, isNot(PassageAudioDecision.speakWithTts));
        expect(decision, isNot(PassageAudioDecision.playNarratorChapter));
        expect(decision, PassageAudioDecision.askBeforeReadAloud);
      }
    });
  });
}
