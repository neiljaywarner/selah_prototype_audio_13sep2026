# Architecture Decision Record (ADR): Scripture Audio Alignment & Timestamp Calibration

## Status
**ACCEPTED** (2026-10-11)

## Context
Selah provides passage meditation loops on curated verse excerpts (e.g. Matthew 11:28–30, Romans 8:31–39, 1 Corinthians 13:4–7). API.Bible provides full-chapter audio streams. To clip the stream accurately and highlight verses in sync with narration, precise millisecond timestamps are required.

Historically, naive segment counting in Whisper output caused severe boundary offsets:
- In Matthew 11, segment 28 mapped to verse 19 ("drinking") at 148.0s instead of verse 28 ("Come to Me") at 257.5s.
- In Romans 8, segment 31 mapped to verse 25 at 205.0s instead of verse 31 at 301.1s.

Furthermore, audio licensing varies widely between translations:
- **BSB** (Berean Standard Bible): Open translation, public domain/Creative Commons audio.
- **WEB** (World English Bible): Public domain text and audio.
- **NIV** (New International Version): Proprietary copyright owned by Biblica, Inc., licensed by Zondervan. License terms forbid downloading or locally storing audio files.

## Decisions

### 1. Acoustic Waveform Snapping & WPS Rate Sanity
Rather than trusting raw speech-to-text segment numbers, timestamp calibration must use:
1. **FFmpeg Silence Detection**: Snapping start/end markers to natural narrator pauses (0.3s–1.5s).
2. **Words-Per-Second (WPS) Validation**: Ensuring human speech rates fall between 1.0 and 5.2 WPS.
3. **Monotonicity & Non-Inversion**: `startMs < endMs` and sequential ordering.

### 2. Translation Scoping for Curated Excerpts
- **Authorized for Offline Excerpts**: BSB and WEB. Local MP3 downloading and offline JSON caching are permitted and tested.
- **Restricted for Proprietary Translations**: NIV audio files must NEVER be saved to disk. Excerpt clipping for NIV is deferred until ephemeral in-memory slicing compliance is established.

### 3. Automated Unit Testing
A regression test suite (`test/unit/curated_timestamps_validation_test.dart`) executes during continuous integration, asserting that no excerpt regressions can be committed to source control.

## Consequences
- **Positive**: Eliminates audio start glitches on curated passages. Users hear the exact opening word of the passage.
- **Positive**: Full copyright compliance; zero risk of unauthorized caching of proprietary Biblica assets.
- **Trade-off**: Adding new passages requires running the calibration tool (`scripts/verify_and_calibrate_timestamps.py`) to verify silence pauses before committing JSON assets.
