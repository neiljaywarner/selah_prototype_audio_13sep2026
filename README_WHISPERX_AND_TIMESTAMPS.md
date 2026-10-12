# WhisperX Audio Alignment & Timestamp Calibration Engine

## 1. Overview & Architectural Goals
In **Selah**, users meditate on targeted Scripture passages—often specific verse excerpts (such as **Matthew 11:28–30**, **Romans 8:31–39**, or **1 Corinthians 13:4–7**)—rather than entire multi-minute chapters. 

However, upstream audio providers (including **API.Bible**) distribute narration strictly as **full-chapter audio files** (e.g. `MAT_011.mp3`, duration: 4m 39s). To deliver seamless meditation loops, Selah clips chapter audio at the exact verse boundary using `just_audio`'s `ClippingAudioSource` and drives real-time karaoke verse highlighting using lightweight 2 KB JSON assets (`assets/timestamps/<TRANSLATION>/<BOOK>_<CHAPTER>.json`).

This guide details:
1. **The Root Cause Analysis (RCA)** of historical timestamp boundary misalignments.
2. **The Multi-Layered Calibration Algorithm** combining WhisperX phoneme alignment, FFmpeg acoustic waveform silence profiling, and human speech rate (WPS) heuristics.
3. **Copyright & Licensing Safeguards** ensuring compliance with public domain vs. proprietary audio boundaries.
4. **Step-by-Step Operator Runbook** for calibrating new passages without human guesswork.

---

## 2. Root Cause Analysis (RCA): Why Matthew 11 & Romans 8 Were Offset

### The Bug Signature
- **Matthew 11:28–30**: Audio playback began with the narrator saying *"eating and drinking"* (verse 19) at **02:28 (148.0s)**, despite the on-screen text showing verse 28 (*"Come to Me, all you who are weary..."*).
- **Romans 8:31–39**: Audio was truncated, stopping playback before the concluding verses because timestamps were hardcoded between 205s and 277s out of a 389s file.

### The Technical Root Cause
In initial alignment prototypes (`scripts/batch_align_whisperx.py`), the alignment pipeline processed Whisper speech segments using a linear loop:
```python
# ❌ BUGGY PATTERN in scripts/batch_align_whisperx.py:
verse_counter = 1
for segment in aligned_result.get("segments", []):
    timestamps.append({
        "verse": verse_counter,
        "text": segment["text"],
        "startMs": int(segment["start"] * 1000),
        "endMs": int(segment["end"] * 1000)
    })
    verse_counter += 1
```
**Why this failed catastrophically**:
1. Whisper outputs **acoustic speech phrases / sentence chunks**, NOT canonical Bible verses.
2. Chapter headers (*"Chapter Eleven"*), long verses split into multiple punctuation clauses, and narrator breath pauses generated **45+ speech segments** for a 30-verse chapter.
3. As a result, segment index `28` mapped to **verse 19** (*"a friend of tax collectors and sinners... eating and drinking"* at 148,000ms), while the real verse 28 occurred at segment 42 (**257,570ms**)!
4. The same segment-counter drift caused Romans 8:31 (actual audio at 301,150ms) to be assigned the timestamp of segment 31 (205,000ms).

---

## 3. The 3-Tier Verification & Calibration Algorithm

To prevent alignment drift, Selah employs a 3-tier calibration engine:

```
┌────────────────────────────────────────────────────────┐
│ Tier 1: Phoneme & Word Alignment (WhisperX / Wav2Vec2)  │
│ Generates word-level timestamps when ML host available│
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Tier 2: Acoustic Silence Detection (FFmpeg filter)    │
│ Detects inter-verse silence pauses (0.3s - 1.5s)      │
│ Clean BSB: noise=-28dB | Drama WEB: noise=-20dB       │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Tier 3: Human Speech Rate (WPS) Heuristic Sanity Gate  │
│ Words Per Second = word_count / duration_sec           │
│ Valid Pacing Range: 1.0 <= WPS <= 5.0 (avg: 2.2-2.8)   │
└────────────────────────────────────────────────────────┘
```

### 1. Acoustic Waveform Silence Profiling (FFmpeg)
Narrators naturally pause between verses for **0.5s to 1.5s**, and between sentences for **0.3s to 0.6s**. Using FFmpeg's `silencedetect` audio filter, we detect all acoustic pauses:
```bash
# Non-drama narrator (e.g. BSB):
ffmpeg -i MAT_011.mp3 -af "silencedetect=noise=-28dB:d=0.35" -f null -

# Drama narrator with ambient music (e.g. WEB):
ffmpeg -i MAT_011.mp3 -af "silencedetect=noise=-20dB:d=0.25" -f null -
```
**Calibrated Boundary Snapping**:
- `startMs` snaps to the **end of the preceding silence gap** (`pause_end + 50ms`).
- `endMs` snaps to the **start of the succeeding silence gap** (`pause_start - 50ms`).

### 2. Speech Rate (WPS / WPM) Sanity Gate
The engine computes the speech velocity for every single verse:
$$\text{WPS} = \frac{\text{Word Count}}{\text{Duration (seconds)}}$$
- **Standard Narration**: `2.2 – 2.8 WPS` (132 – 168 WPM).
- **Dramatic Reading**: Up to `3.8 – 4.9 WPS` during impassioned passages.
- **Anomaly Flags**:
  - `WPS < 1.0`: Boundary includes excessive silence or wrong verse chunk.
  - `WPS > 5.2`: Boundary is truncated; verse was clipped prematurely.

---

## 4. Ground Truth Calibrated Boundaries

### Matthew 11:28–30
| Translation | Total Audio Dur | Excerpt Verse | startMs | endMs | Words | Dur (s) | WPS | Acoustic Pause Verified |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **BSB** | 279.33s | **v28** | 257,570 | 263,500 | 16 | 5.93s | 2.70 | Yes (after 1.41s pause at 256.16–257.57s) |
| **BSB** | 279.33s | **v29** | 264,100 | 273,500 | 25 | 9.40s | 2.66 | Yes (after 0.88s pause at 263.26–264.14s) |
| **BSB** | 279.33s | **v30** | 274,100 | 277,800 | 10 | 3.70s | 2.70 | Yes (after 0.68s pause at 273.48–274.16s) |
| **WEB** | 252.60s | **v28** | 235,330 | 243,300 | 17 | 7.97s | 2.13 | Yes (after 0.54s pause at 234.79–235.33s) |
| **WEB** | 252.60s | **v29** | 243,300 | 248,400 | 25 | 5.10s | 4.90 | Yes (drama pace across 243.6–248.4s) |
| **WEB** | 252.60s | **v30** | 248,400 | 250,400 | 10 | 2.00s | 5.00 | Yes (before 2.20s end silence at 250.4s) |

### Romans 8:31–39
| Translation | Total Audio Dur | Excerpt Range | startMs | endMs | Total Words | WPS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **BSB** | 389.38s | v31 – v39 | 301,150 | 387,700 | 181 words | 2.45 avg |
| **WEB** | 323.89s | v31 – v39 | 254,300 | 321,600 | 180 words | 2.71 avg |

---

## 5. Architectural Decision Record (ADR): Copyright & Translation Governance

### Context
Upstream audio providers grant different licensing permissions based on translation:
- **Public Domain / Creative Commons (BSB, WEB)**: Permitted for offline timestamp generation, local audio downloading for acoustic analysis, and offline JSON bundling.
- **Proprietary / Licensed (NIV - Biblica / Zondervan)**: License agreements strictly forbid saving, caching, or redistributing MP3 audio files on disk. Audio must only be streamed ephemerally via signed API.Bible URLs at runtime.

### Decision
1. **Passage Excerpts Restricted to Open Translations**:
   Curated verse ranges (`PassageExcerpt`) and offline timestamp JSON assets are officially supported for **BSB** and **WEB**.
2. **Proprietary Translations Play Full Chapters**:
   When playing NIV, chapters are streamed in full ephemerally. Local caching of NIV MP3 files is blocked by code assertions in `scripts/api_bible_fetch.sh`.
3. **Follow-Up Investigation**:
   Tracked under a dedicated GitHub issue to explore whether ephemeral, in-memory audio clipping for proprietary streams complies with API.Bible terms.

---

## 6. CLI Tools & Operational Runbook

### Tool 1: `scripts/api_bible_fetch.sh`
Safely interacts with API.Bible with zero secret leakage:
```bash
# 1. Fetch signed ephemeral streaming URL
./scripts/api_bible_fetch.sh get-audio-url --translation BSB --book MAT --chapter 11

# 2. Download audio for open translation (BSB, WEB) to local path for alignment
./scripts/api_bible_fetch.sh download-audio --translation BSB --book MAT --chapter 11 --out /tmp/bsb_mat11.mp3

# 3. Probe audio duration and bitrate
./scripts/api_bible_fetch.sh probe-audio --translation WEB --book ROM --chapter 8

# 4. Attempting to download proprietary audio is REJECTED by copyright guard:
./scripts/api_bible_fetch.sh download-audio --translation NIV --book MAT --chapter 11 --out /tmp/niv.mp3
# -> 🛑 LEGAL / COPYRIGHT REJECTION: Downloading audio for proprietary translation 'NIV' is strictly prohibited.
```

### Tool 2: `scripts/verify_and_calibrate_timestamps.py`
Audits schema, monotonicity, speaking rates, and acoustic pause alignment:
```bash
# Audit existing JSON file
./scripts/verify_and_calibrate_timestamps.py --json assets/timestamps/BSB/MAT_11.json

# Audit with audio file & acoustic pause verification
./scripts/verify_and_calibrate_timestamps.py \
  --json assets/timestamps/BSB/MAT_11.json \
  --audio /tmp/bsb_mat11.mp3 \
  --noise-thresh -28dB

# Calibrate and snap boundaries to silence pauses
./scripts/verify_and_calibrate_timestamps.py \
  --json assets/timestamps/BSB/MAT_11.json \
  --audio /tmp/bsb_mat11.mp3 \
  --calibrate
```

### Automated Unit Tests
Run the comprehensive verification test suite:
```bash
flutter test test/unit/curated_timestamps_validation_test.dart
```
This test asserts:
- Valid schema and monotonic order for every timestamp JSON.
- Speech rate velocity is within human bounds (0.9 – 5.5 WPS).
- Matthew 11:28 starts at $\ge$ 250,000ms (BSB) / $\ge$ 235,000ms (WEB).
- Romans 8:31 starts at $\ge$ 295,000ms (BSB) / $\ge$ 250,000ms (WEB).
- All items in `kCuratedExcerpts` resolve to valid non-null `ClipWindows`.
