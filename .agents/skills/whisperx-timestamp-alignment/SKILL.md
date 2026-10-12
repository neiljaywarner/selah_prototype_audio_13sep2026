---
name: whisperx-timestamp-alignment
description: >-
  Iteratively extracts, aligns, calibrates, and verifies verse-level audio timestamps
  for Scripture passages using WhisperX, FFmpeg acoustic silence profiling, and speech-rate heuristics.
---

# WhisperX Scripture Audio Alignment & Calibration Skill

Use this skill whenever:
1. Adding a new curated passage or verse excerpt to Selah.
2. Investigating audio start cutoff bugs (e.g., audio starts on preceding verse dialogue).
3. Calibrating `startMs` and `endMs` boundaries when automated scripts are not 100% proven yet.
4. Validating monotonicity and human speaking rates (WPS) across multi-translation audio streams.

---

## 1. Golden Rules & Hard Constraints
1. **Never Assume Whisper Segment Index Equals Verse Number**:
   - Whisper outputs acoustic phrases and sentence clauses, NOT canonical Bible verses.
   - Preamble titles (*"Chapter Eleven"*) and multi-clause sentences create extra segments.
   - Always align against the canonical verse text and verse numbers!
2. **Respect Copyright & Licensing Boundaries**:
   - Audio downloads and offline timestamp generation are permitted ONLY for Public Domain / Open translations (**BSB**, **WEB**).
   - NEVER download or cache proprietary audio (e.g. **NIV**).
3. **Never Hardcode Guesses Without Acoustic Silence Verification**:
   - Always verify that `startMs` falls inside the silence gap preceding the verse.
   - Always verify that `endMs` falls inside the silence gap succeeding the verse.
   - Average narrator pacing is **2.2 to 2.8 Words Per Second (WPS)**. Flag any verse with WPS < 1.0 or WPS > 5.2.

---

## 2. Iterative Calibration Workflow for AI Agents

When tasked with calibrating a chapter or excerpt where scripts aren't "perfectly proven yet":

### Step 1: Fetch Audio & Metadata via CLI
Run the zero-secret API.Bible fetcher:
```bash
# Get duration & info
./scripts/api_bible_fetch.sh probe-audio --translation BSB --book <BOOK> --chapter <N>

# Download temporary audio for open translation
./scripts/api_bible_fetch.sh download-audio --translation BSB --book <BOOK> --chapter <N> --out /tmp/<trans>_<book>_<chapter>.mp3
```

### Step 2: Run Acoustic Silence Detection via FFmpeg
Run silence detection to find natural inter-verse pauses:
```bash
# Clean voice narration (e.g. BSB):
ffmpeg -i /tmp/<audio>.mp3 -af "silencedetect=noise=-28dB:d=0.35" -f null - 2>&1 | grep silence_

# Drama narration with background music/effects (e.g. WEB):
ffmpeg -i /tmp/<audio>.mp3 -af "silencedetect=noise=-20dB:d=0.25" -f null - 2>&1 | grep silence_
```

### Step 3: Run the Automated Audit & Calibration Engine
Execute:
```bash
./scripts/verify_and_calibrate_timestamps.py \
  --json assets/timestamps/<TRANSLATION>/<BOOK>_<CHAPTER>.json \
  --audio /tmp/<audio>.mp3 \
  --calibrate
```
Inspect the output:
- Verify that `startMs` lands in an acoustic pause (`✅ In pause`).
- Verify that every verse has valid speech pacing (`✅ OK` at 2.0–3.5 WPS).
- If any verse shows `[⚠️ SUSPICIOUS]`, adjust the noise threshold or check for drama pacing.

### Step 4: Verify with Automated Unit Tests
Run the test suite:
```bash
flutter test test/unit/curated_timestamps_validation_test.dart
```

### Step 5: Test on Physical Device or Emulator
1. Connect via ADB or iOS Simulator.
2. Trigger hot reload or hot restart:
   - For running Flutter daemon: send `r` (hot reload) or `R` (hot restart).
3. Play the curated excerpt:
   - Verify the narrator begins on the **first syllable** of the target verse.
   - Verify karaoke text highlighting tracks narrator speech.
   - Verify the 4-second prayer reflection gap triggers at the end of the excerpt.

---

## 3. Heuristic Quick Reference
- **Expected Verse Duration**: $\text{Duration (seconds)} \approx \frac{\text{Word Count}}{2.4}$
- **Inter-verse Pause**: Typically `0.6s to 1.5s` of relative silence between verses.
- **Mid-verse Clause Pause**: Typically `0.3s to 0.5s` at commas/semicolons.
- **Snapping Offset**: Add `+50ms` padding after pause end for `startMs`; subtract `-50ms` before pause start for `endMs`.
