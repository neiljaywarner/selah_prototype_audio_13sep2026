# User, Tester & Product Guide: Audio Timestamp Calibration in Selah

## 1. What is Passage Meditation & Why Does Calibration Matter?
When meditating on Scripture in Selah, a user selects a preset card such as **Matt 11:28–30 ("Come to Me")**.
Instead of playing the entire chapter from verse 1 ("After Jesus had finished instructing His twelve disciples..."), Selah:
1. Buffers the audio stream.
2. Directly seeks/clips to the exact opening syllable of Verse 28 (*"Come to Me..."*).
3. Plays through the passage in high-fidelity audio.
4. Highlights the current spoken verse in real-time (karaoke highlighting).
5. Pauses for 4 seconds in silence for prayerful reflection.
6. Automatically loops for the user's selected repetition count (e.g. 3 iterations).

If timestamps are off by even a few seconds, the user hears confusing cutoffs or preceding dialogue (such as verse 19's "eating and drinking"), which breaks the contemplative experience.

---

## 2. Supported Translations for Passage Excerpts
| Translation | Category | Passage Excerpts Supported? | Why? |
| :--- | :--- | :--- | :--- |
| **BSB (Berean Standard Bible)** | Open / Creative Commons | ✅ **YES (Full Support)** | Public domain narration, verified silence boundaries, bundled offline. |
| **WEB (World English Bible)** | Public Domain | ✅ **YES (Full Support)** | Public domain drama narration, calibrated drama pacing, bundled offline. |
| **NIV (New International Version)** | Proprietary / Biblica | ℹ️ **Full Chapter Only** | Strict license terms prohibit offline caching. Streamed ephemerally. |

---

## 3. How to Test & Verify a Calibrated Passage

### On Physical Devices (e.g. Google Pixel 9a) or Simulators:
1. Launch the Selah app with `API_BIBLE_KEY` configured.
2. Tap the **Matt 11:28–30** chip.
3. Observe:
   - The audio starts **immediately** with the narrator saying *"Come to Me, all you who are weary..."*.
   - The elapsed timer shows the clipped duration (~20 to 24 seconds total), not 04:39.
   - Verse 28 is highlighted in primary theme color.
   - When the verse completes, highlighting transitions seamlessly to Verse 29, then Verse 30.
   - After Verse 30, the player enters the 4-second prayer reflection gap before seamlessly repeating.
4. Tap the **Rom 8:31–39** chip.
   - Observe the audio starts directly with *"What then shall we say in response to these things?"*.
   - All 9 verses play consecutively through verse 39 without early cutoff.

---

## 4. Troubleshooting Checklist for Testers
- **Symptom: Narrator starts mid-word or ends mid-word**:
  - Run `./scripts/verify_and_calibrate_timestamps.py --json <path> --audio <stream>`.
  - Check whether `startMs` or `endMs` lands in speech rather than an acoustic pause.
  - Snap boundaries to the nearest detected pause using `--calibrate`.
- **Symptom: Speech rate shows `[SUSPICIOUS]` warning**:
  - Check if the verse has fewer words than usual or if background drama music extended the duration.
  - Recalibrate noise threshold (`-20dB` for drama audio vs `-28dB` for clean spoken voice).
