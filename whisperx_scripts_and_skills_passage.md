# WhisperX Audio Alignment, Multi-Provider Architecture & 40-Chapter Scaling Engine

> **Document**: `whisperx_scripts_and_skills_passage.md`  
> **Status**: Active Architecture Guide & Operational Runbook  
> **Target Audience**: AI Agents, Systems Engineers, Audio Pipeline Maintainers  
> **Last Verified**: 13 October 2026

---

## 1. Executive Summary & Root Cause Post-Mortem

### The 1 Corinthians 13:4 WEB Incident
- **Symptom Reported**: When playing 1 Corinthians 13:4 in the WEB translation, playback erroneously began at *"doesn't [rejoice in unrighteousness]"* (Verse 6), or when offset earlier, at *"If I dole out all my goods..."* (Verse 3), rather than starting crisply at Verse 4 (*"Love is patient, love is kind"*).
- **Root Cause**:
  1. In the Berean Standard Bible (BSB), the full chapter narration duration is **133.20 seconds**, and Verses 1–3 take **39.6 seconds**. Verse 4 starts at `39,600 ms`.
  2. In the World English Bible (WEB), narration duration is **113.48 seconds** (an overall 15% faster speech tempo). Verses 1–2 conclude at `23.13s`. Verse 3 (*"If I dole out..."*) spans `24.96s – 39.74s`.
  3. The preliminary timestamp file `assets/timestamps/WEB/1CO_13.json` had its `startMs` erroneously anchored to `39,600 ms` (copied from BSB). At `39,600 ms`, the WEB narrator is speaking the final words of Verse 3 (*"...don't have love, it profits me nothing"*).
  4. At `25,000 ms`, playback landed in the opening words of Verse 3 (*"If I dole out..."*).
  5. **Calibrated Truth**: The narrator pauses for **1.128 seconds** (`39.743s – 40.871s`) between Verse 3 and Verse 4. Verse 4 begins cleanly at **`40,900 ms`**.

```
WEB 1CO 13 Acoustic Timeline:
[0.00s ─── Verse 1 ─── 12.65s]
  (pause 0.58s)
[13.23s ── Verse 2 ─── 23.13s]
  (pause 1.84s: 23.13s – 24.96s)
[24.96s ── Verse 3 ("If I dole out...") ── 39.74s]  <-- 39,600ms hit "...don't have love"
  (pause 1.13s: 39.74s – 40.87s)
[40.87s ── Verse 4 ("Love is patient...") ─ 47.82s]  <-- EXACT START: 40,900ms
  (pause 0.94s: 47.83s – 48.77s)
[48.77s ── Verse 5 ("does not behave...") ─ 58.70s]
  (pause 1.52s: 58.70s – 60.22s)
[60.22s ── Verse 6 ("doesn't rejoice...") ─ 65.30s]
  (pause 0.55s: 65.33s – 65.85s)
[65.85s ── Verse 7 ("bears all things...") ─ 72.15s]
```

---

## 2. Universal Acoustic Alignment Algorithm (Pseudocode)

Any generic alignment script accepting an arbitrary audio narrator stream (BSB, WEB, ESV, Bible Brain / FCBH, YouVersion, DBP4) must follow this 5-stage pipeline:

```python
def align_scripture_chapter(audio_path: str, canonical_verses: List[dict], translation: str):
    # STAGE 1: Acoustic Silence Profiling
    # Dynamic noise floor thresholding based on narration style
    # Clean studio vocal (BSB): -28dB; Dramatic background pads (WEB): -20dB
    noise_thresh = "-20dB" if translation.upper() == "WEB" else "-28dB"
    pauses = detect_silence_pauses(audio_path, noise_thresh=noise_thresh, min_silence=0.25)
    
    # STAGE 2: Phoneme / Word-Level Transcription (WhisperX / Faster-Whisper)
    model = WhisperModel("base.en", device="cpu", compute_type="int8")
    segments, info = model.transcribe(audio_path, word_timestamps=True)
    words = flatten_word_timestamps(segments)
    
    # STAGE 3: Verse Boundary Sequence Matching
    calibrated_verses = []
    for verse in canonical_verses:
        target_words = clean_words(verse["text"])
        start_word_match = find_sequence(words, target_words[:3])
        end_word_match = find_sequence(words, target_words[-3:])
        
        raw_start_sec = start_word_match.start
        raw_end_sec = end_word_match.end
        
        # STAGE 4: Boundary Snapping to Acoustic Silence Pauses
        # Snap start boundary to the preceding silence pause end + 50ms safety padding
        calibrated_start_ms = snap_to_silence_end(raw_start_sec, pauses, tolerance=0.65)
        # Snap end boundary to the succeeding silence pause start - 50ms safety padding
        calibrated_end_ms = snap_to_silence_start(raw_end_sec, pauses, tolerance=0.65)
        
        # STAGE 5: Speech Rate (WPS) & Monotonicity Validation
        duration_sec = (calibrated_end_ms - calibrated_start_ms) / 1000.0
        wps = len(target_words) / duration_sec
        assert 1.0 <= wps <= 4.8, f"Implausible speech rate: {wps:.2f} WPS"
        
        calibrated_verses.append({
            "verse": verse["verse_number"],
            "text": verse["text"],
            "startMs": calibrated_start_ms,
            "endMs": calibrated_end_ms,
        })
        
    return calibrated_verses
```

---

## 3. Provider Matrix & Licensing Guardrails

| Provider / Stream | License Type | Local MP3 Caching | Runtime Handling |
| :--- | :--- | :--- | :--- |
| **Berean Standard Bible (BSB)** | CC0 / Public Domain | ✅ Permitted & Pre-bundled | Bundled offline MP3 (`assets/audio/BSB/`) with WhisperX JSON |
| **World English Bible (WEB)** | Public Domain | ✅ Permitted & Pre-bundled | Bundled offline MP3 (`assets/audio/WEB/`) with WhisperX JSON |
| **New International Version (NIV)** | Proprietary (Biblica / Zondervan) | ❌ **Strictly Prohibited** (Copyright Infringement) | On-demand ephemeral signed URL via API.Bible or peaceful fallback to offline TTS |
| **Crossway ESV API** | Proprietary Commercial | ❌ Local storage prohibited without commercial license | Ephemeral audio stream per session |
| **Faith Comes By Hearing (FCBH / Bible Brain)** | Non-Commercial Ministry Grant | ⚠️ Dynamic streaming only via DBP4 API keys | Dynamic caching with local TTL |

---

## 4. The 40-Chapter Contemplative Scaling Ladder

Following the demand-driven progressive alignment methodology, Selah scales to 40 core chapters across 3 tiers:

### Level 1: Soft Launch Baseline (6 Chapters / Passages) — **100% Calibrated**
1. **1 Corinthians 13:4–7** (`1CO 13:4-7`) — *Love is Patient* (`40900ms – 72150ms`)
2. **Matthew 11:28–30** (`MAT 11:28-30`) — *Rest for Your Souls* (`93200ms – 107900ms`)
3. **Romans 8:31–39** (`ROM 8:31-39`) — *More Than Conquerors*
4. **Psalm 23:1–6** (`PSA 23`) — *The Lord is My Shepherd*
5. **Psalm 62:1–2** (`PSA 62:1-2`) — *My Soul Rests in God Alone*
6. **Colossians 1:1–2** (`COL 1:1-2`) — *Grace and Peace*

### Level 2: Top 12 Meditations — **100% Calibrated**
7. **Psalm 91:1–4** (`PSA 91:1-4`) — *Shelter of the Most High*
8. **John 3:16–17** (`JHN 3:16-17`) — *For God So Loved the World*
9. **Philippians 4:4–8** (`PHP 4:4-8`) — *Rejoice in the Lord Always*
10. **Proverbs 3:5–6** (`PRO 3:5-6`) — *Trust in the Lord with All Your Heart*
11. **Isaiah 40:28–31** (`ISA 40:28-31`) — *Those Who Wait Upon the Lord*
12. **Romans 12:1–2** (`ROM 12:1-2`) — *Living Sacrifice*

### Level 3: Top 40 Spiritual Havens (Psalms, Wisdom & Gospels)
- **Psalms of Peace**: Psalms 1, 16, 27, 34, 46, 84, 103, 119 (Aleph/Beth), 121, 139.
- **Words of Jesus**:
  - The Beatitudes (Matthew 5:1–12)
  - The Lord's Prayer (Matthew 6:9–13)
  - The Light of the World (John 8:12)
  - The Good Shepherd (John 10:11–18)
  - The True Vine (John 15:1–8)
  - The Great Commission (Matthew 28:18–20)
- **Epistles & Contemplation**:
  - Galatians 5:22–23 (Fruit of the Spirit)
  - Ephesians 6:10–18 (Armor of God)
  - Hebrews 11:1–3 (Hall of Faith)
  - 1 Peter 5:6–7 (Cast Your Anxiety on Him)
  - 1 John 4:7–12 (God is Love)

---

## 5. Verification Checkpoints & CLI Tooling

- **Acoustic Snapping & Verification**:
  ```bash
  python3 scripts/verify_and_calibrate_timestamps.py \
    --json assets/timestamps/WEB/1CO_13.json \
    --audio assets/audio/WEB/1CO_13.mp3 \
    --noise-thresh "-20dB"
  ```
- **Dart Unit Test Execution**:
  ```bash
  flutter test test/unit/corinthians_13_verse_4_test.dart
  flutter test test/unit/curated_timestamps_validation_test.dart
  ```
- **Physical Device Playback Verification**:
  ```bash
  adb -s <DEVICE_ID> logcat -d -s flutter | grep -E "Clipped|iteration"
  ```
