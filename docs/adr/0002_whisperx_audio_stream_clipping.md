# Architecture Decision Record: ADR-0002
# Client-Side Audio Stream Clipping via WhisperX Timestamps

* **Status**: Accepted
* **Date**: 2026-10-11
* **Deciders**: Engineering Lead, Product Architecture
* **Related Issues / PRs**: PR #18, Issue #1, Issue #19

---

## 1. Non-Technical Summary

When you listen to Scripture audio online, the audio is provided in complete chapters (for example, all 5 minutes of 1 Corinthians 13). However, people who meditate on Scripture often want to focus deeply on just a small portion, such as verses 4–7 ("Love is patient, love is kind").

We had two ways to solve this:
1. **Server-Side Audio Chopping**: Build a backend server that slices up audio files and saves thousands of small MP3 clips. (This is expensive to host, takes significant time to process, and requires complex copyright handling).
2. **Client-Side Smart Needle Drop**: Stream the official full chapter directly on the user's phone, but use an AI alignment map (**WhisperX**) that knows the exact millisecond where each verse starts and stops, instructing the phone's audio player to instantly jump to verse 4 and stop after verse 7.

**Our Decision**: We chose **Option 2**. It costs $0 in server hosting, operates with zero extra download delay for the user, supports offline caching, and gives us sub-second accuracy across different Bible translations.

---

## 2. Technical Context & Problem Statement

API.Bible provides audio streams exclusively at the whole-chapter granularity (e.g. `audioBibleId/chapters/{chapterId}` returns a single continuous MP3 stream URL).

For deep meditation, users require:
1. Instant playback of targeted excerpts (e.g., `1 Cor 13:4–7`, `Matt 11:28–30`, `Rom 8:31–39`, `Psalm 23`).
2. Looping repetitions bounded strictly within the excerpt boundaries.
3. Synchronized karaoke text highlighting.
4. Smooth translation switching (e.g. BSB <-> WEB) without losing excerpt context.

---

## 3. Decision

We integrate **WhisperX phoneme/word-level forced alignment** offline to produce compact verse timestamp maps (`assets/timestamps/{TRANSLATION}/{BOOK}_{CHAPTER}.json`).

At runtime:
1. `PassageExcerpt.forChapter(bookCode, chapterNumber)` identifies whether an excerpt window is requested.
2. `clipWindow(timestamps)` computes `(start: Duration, end: Duration)`.
3. The audio engine uses `just_audio`'s native clipping API:
   ```dart
   final dur = await _audioPlayer.setClip(start: window.start, end: window.end);
   ```
4. Looping cycles re-invoke `setClip` and seek to `Duration.zero` (relative to the clipped window start).
5. Uncurated custom verse searches (e.g. `col 1:17-20`) are guarded with a floating SnackBar informing the user that whole-chapter audio is available while automated alignment is queued for `v0.3.0`.

---

## 4. Alternatives Considered

| Alternative | Evaluation | Rationale for Rejection |
| :--- | :--- | :--- |
| **Server-Side FFmpeg Trimming** | High server cost, egress bandwidth overhead, latency before first sound. | Rejected in favor of zero-infrastructure client-side clipping. |
| **Text-to-Speech (TTS) Only** | Instant generation, low size. | Lacks the emotional cadence, warmth, and reverence of professional human narration. (Retained purely as fallback). |
| **Manual User Seeking** | Zero engineering cost. | Destroys the hands-free meditation and walking experience. |

---

## 5. Consequences & Future Extensions

* **Positive**:
  - Instant startup: uses existing CDN stream URLs without intermediate processing.
  - Sub-second precision for verse looping and karaoke text highlighting.
  - Public domain translations (BSB, WEB) bundled with offline text and timestamps for airplane-mode reliability.
* **Negative / Limitations**:
  - Requires pre-computed WhisperX JSON timestamp files for each chapter.
  - Currently limited to curated excerpts (expanded in `v0.3.0` via Issue #19 whole-Bible alignment pipeline).
