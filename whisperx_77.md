# WhisperX 77: The Scalable Scripture Audio Alignment Roadmap (12 ➔ 40 ➔ 77)

> **Core Thesis**: *Scaling acoustic alignment from 12 to 40 to 77 passages must get exponentially easier, not bogged down.*  
> By abstracting narrator voice profiles, establishing automated silence snapping, and separating **Big Learnings** (GitHub PBI) from **Small Learnings** (this markdown log), each new batch requires less manual intervention.

---

## 🧭 1. Architectural Scaling Law: Why It Gets Easier

| Cohort Tier | Passages | Methodology | Human Effort / Passage | Primary Bottleneck Solved |
| :--- | :---: | :--- | :---: | :--- |
| **Tier 1: Curated 12** | 1–12 | Manual WhisperX alignment, FFmpeg silence verification, boundary debugging | ~15 mins | Established JSON schema, unit tests, and MediaItem tag isolation |
| **Tier 2: Biblical 40** | 13–40 | Pre-profiled book silence presets, batch acoustic snapping, automated monotonicity checks | ~3 mins | Eliminated manual silence detection runs by reusing book-level audio profiles |
| **Tier 3: The 77 Cohort** | 41–77 | Fully automated WhisperX acoustic pipeline with heuristic fallback & spot check | < 1 min | 100% test-suite validation (`curated_timestamps_validation_test.dart`) |

---

## 🧠 2. Big Learnings vs. Small Learnings Protocol

To keep engineering velocity high and avoid cognitive drag:
* **🏛️ Big Learnings (Logged to GitHub Issues / Epics)**:
  1. *Licensing & FUMS Guardrails*: BSB and WEB are open and eligible for offline timestamps. Proprietary translations (NIV) use streaming-only dynamic evaluation.
  2. *The Preamble Offset Law*: Chapter intro preambles (*"Chapter 23, A Psalm of David"*) range from 1,200ms to 3,400ms. Slicing verse 1 requires snapping *after* the title pause.
  3. *Audio Crossfade*: 150ms–200ms smooth volume crossfade on loop boundaries completely eliminates audio pop artifacts.
  4. *Heuristic Fallback Snapping*: If WhisperX acoustic alignment is missing, word-count and syllable heuristics (~140 wpm + 400ms punctuation pause) provide seamless human audio playback without robotic TTS.

* **📝 Small Learnings (Logged Directly in this File)**:
  - *Psalms Narration Cadence*: Davidic psalms have a 0.8s–1.2s reflective pause between stanzas.
  - *Drama Soundscapes (WEB)*: Background synth pads require raising silence threshold to `-20dB` to prevent false pause detection.
  - *Max McLean Narration (NIV)*: Powerful emphatic delivery; syllable cadence is 2.6 WPS; clause pauses are sharp (250–350ms).

---

## 🎛️ 3. Standardized Acoustic Silence Presets

```bash
# Clean Spoken Narration (BSB):
ffmpeg -i input.mp3 -af "silencedetect=noise=-28dB:d=0.35" -f null -

# Drama Soundscapes with Ambient FX (WEB):
ffmpeg -i input.mp3 -af "silencedetect=noise=-20dB:d=0.25" -f null -

# Emphatic Classical Narration (NIV Max McLean):
ffmpeg -i input.mp3 -af "silencedetect=noise=-26dB:d=0.30" -f null -
```

---

## 📊 4. The 77 Passage Catalog & Tracking Matrix

### Batch 1: The Curated 12 (Complete ✅)
| # | Reference | Book | Chapter | Verses | BSB | WEB | NIV | Pacing (WPS) | Small Learning / Notes |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| 1 | 1 Corinthians 13:4–7 | 1CO | 13 | 4–7 | ✅ | ✅ | ✅ | 2.4 | Max McLean start boundary: 14,880ms. |
| 2 | Matthew 11:28–30 | MAT | 11 | 28–30 | ✅ | ✅ | 🟡 | 2.5 | Gentle rest invitation; long pause after v28. |
| 3 | Romans 8:31–39 | ROM | 8 | 31–39 | ✅ | ✅ | 🟡 | 2.7 | Climax of Romans 8; steady cadence. |
| 4 | Psalm 23:1–6 | PSA | 23 | 1–6 | ✅ | ✅ | 🟡 | 2.1 | Preamble title is 2,400ms long. |
| 5 | Psalm 91:1–4 | PSA | 91 | 1–4 | ✅ | ✅ | 🟡 | 2.2 | Secret place of the Most High; deep reverb. |
| 6 | John 3:16–17 | JHN | 3 | 16–17 | ✅ | ✅ | 🟡 | 2.6 | Familiar cadence, easy pause detection. |
| 7 | Philippians 4:4–8 | PHP | 4 | 4–8 | ✅ | ✅ | 🟡 | 2.4 | Peace of God guarding hearts; gentle rhythm. |
| 8 | Proverbs 3:5–6 | PRO | 3 | 5–6 | ✅ | ✅ | 🟡 | 2.3 | Trust in the Lord; sharp 400ms colon pause. |
| 9 | Isaiah 40:28–31 | ISA | 40 | 28–31 | ✅ | ✅ | 🟡 | 2.5 | Soar on wings like eagles; soaring cadence. |
| 10 | Romans 12:1–2 | ROM | 12 | 1–2 | ✅ | ✅ | 🟡 | 2.6 | Living sacrifice; clear paragraph break. |
| 11 | Psalm 62:1–2 | PSA | 62 | 1–2 | ✅ | ✅ | 🟡 | 2.0 | Truly my soul finds rest; very slow pacing. |
| 12 | Colossians 1:15–20 | COL | 1 | 15–20 | ✅ | ✅ | 🟡 | 2.8 | Christ hymn; poetic metric rhythm. |

---

### Batch 2: The Biblical 40 (Milestone M86 — In Progress 🟡)
*Focus: Wilderness, Renewal, Healing, Anxiety, and Divine Presence*

| # | Reference | Book | Chapter | Verses | Theme | Status |
| :---: | :--- | :---: | :---: | :---: | :--- | :---: |
| 13 | Psalm 46:1–3, 10 | PSA | 46 | 1–3, 10 | Be Still & Know | ⚪ Queued |
| 14 | Psalm 139:1–10 | PSA | 139 | 1–10 | Known & Searched | ⚪ Queued |
| 15 | Isaiah 43:1–3 | ISA | 43 | 1–3 | Fear Not, Called By Name | ⚪ Queued |
| 16 | Exodus 14:13–14 | EXO | 14 | 13–14 | The Lord Will Fight For You | ⚪ Queued |
| 17 | Matthew 6:25–34 | MAT | 6 | 25–34 | Do Not Be Anxious | ⚪ Queued |
| 18 | Lamentations 3:22–26 | LAM | 3 | 22–26 | Mercies New Every Morning | ⚪ Queued |
| 19 | 2 Corinthians 12:9–10 | 2CO | 12 | 9–10 | Grace is Sufficient | ⚪ Queued |
| 20 | Psalm 27:1–4 | PSA | 27 | 1–4 | The Lord is My Light | ⚪ Queued |
| 21 | Isaiah 26:3–4 | ISA | 26 | 3–4 | Perfect Peace | ⚪ Queued |
| 22 | Zephaniah 3:17 | ZEP | 3 | 17 | Rejoicing Over You With Singing | ⚪ Queued |
| 23 | Psalm 121:1–8 | PSA | 121 | 1–8 | My Help Comes From the Lord | ⚪ Queued |
| 24 | John 14:1–3, 27 | JHN | 14 | 1–3, 27 | Peace I Leave With You | ⚪ Queued |
| 25 | Ephesians 3:16–21 | EPH | 3 | 16–21 | Rooted & Grounded in Love | ⚪ Queued |
| 26 | Romans 8:18, 26–28 | ROM | 8 | 18, 26–28 | The Spirit Intercedes | ⚪ Queued |
| 27 | Psalm 84:1–4, 10 | PSA | 84 | 1–4, 10 | How Lovely is Your Dwelling Place | ⚪ Queued |
| 28 | Hebrews 4:14–16 | HEB | 4 | 14–16 | Throne of Grace | ⚪ Queued |
| 29 | 1 Peter 5:6–7 | 1PE | 5 | 6–7 | Cast All Your Anxiety | ⚪ Queued |
| 30 | Psalm 103:1–5, 11–13 | PSA | 103 | 1–5, 11–13 | Bless the Lord, O My Soul | ⚪ Queued |
| 31 | Isaiah 55:1–3, 10–11 | ISA | 55 | 1–3, 10–11 | Come to the Waters | ⚪ Queued |
| 32 | Matthew 5:3–10 | MAT | 5 | 3–10 | The Beatitudes | ⚪ Queued |
| 33 | 1 John 4:16–19 | 1JN | 4 | 16–19 | Perfect Love Casts Out Fear | ⚪ Queued |
| 34 | Psalm 34:1–8 | PSA | 34 | 1–8 | Taste and See That the Lord is Good | ⚪ Queued |
| 35 | Joshua 1:8–9 | JOS | 1 | 8–9 | Be Strong and Courageous | ⚪ Queued |
| 36 | 2 Corinthians 4:16–18 | 2CO | 4 | 16–18 | Renewed Day by Day | ⚪ Queued |
| 37 | Psalm 42:1–2, 11 | PSA | 42 | 1–2, 11 | As the Deer Pants | ⚪ Queued |
| 38 | Galatians 5:22–25 | GAL | 5 | 22–25 | Fruit of the Spirit | ⚪ Queued |
| 39 | Revelation 21:3–5 | REV | 21 | 3–5 | Behold, I Make All Things New | ⚪ Queued |
| 40 | Deuteronomy 6:4–9 | DEU | 6 | 4–9 | The Shema (Hear, O Israel) | ⚪ Queued |

---

### Batch 3: The Soft Launch 77 (Milestone M87 — Queued ⚪)
*Passages 41–77: One dedicated meditation for each of our 77 Beta Meditators.*
- Focus: Extended contemplative encounters across Psalms, Wisdom literature, Prophets, Gospels, and Epistles.
- Automated generation via `TimestampLoaderService` heuristic acoustic slicing + verified JSON presets.
