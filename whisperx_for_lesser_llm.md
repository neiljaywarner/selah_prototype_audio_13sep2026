# WhisperX & Karaoke Integration Guide (For Lesser LLM Handoff)

This guide provides immediate instructions for resuming, testing, or expanding the WhisperX timestamp alignment feature in **Selah**.

---

## 📁 Key Files & Modules
1. **Timestamp Loader Service**: `lib/src/core/karaoke/timestamp_loader.dart`
   - Loads 2 KB JSON timestamp assets (`assets/timestamps/<TRANSLATION>/<BOOK>_<CHAPTER>.json`).
2. **Audio Position Listener**: `lib/src/features/meditation/application/chapter_player_notifier.dart`
   - In `_posSub`, matches current audio position in milliseconds against `_currentTimestamps` to update `highlightStart` and `highlightEnd`.
3. **Python Batch Alignment Tool**: `scripts/batch_align_whisperx.py`
   - Runs locally on macOS using WhisperX to generate verse-level JSON timestamps.
4. **Sample JSON Assets**:
   - `assets/timestamps/WEB/COL_1.json` (Colossians 1)
   - `assets/timestamps/WEB/PSA_23.json` (Psalm 23)
   - `assets/timestamps/WEB/PSA_62.json` (Psalm 62)
   - `assets/timestamps/WEB/MRK_5.json` (Mark 5)
   - `assets/timestamps/WEB/1COR_13.json` (1 Corinthians 13:4-7 Experimental Preview)

---

## 🚀 How to Run & Test
1. **Run Unit Tests**:
   ```bash
   flutter test
   ```
   *(Verifies timestamp parser and state notifier behavior)*
2. **Generate New Chapter JSON**:
   ```bash
   python3 scripts/batch_align_whisperx.py --translation WEB --book JHN --chapter 1 --audio_source "https://..."
   ```

---

## ⚠️ Important Rules
- **Never push or merge directly into `main`**. Always work on feature branches (e.g., `feat/analytics_and_web_audio_narrator`).
- **Zero API Key Leaks**: `AppLogger._sanitize(...)` automatically redacts sensitive keys from logs and analytics payloads.
