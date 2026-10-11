# Rule: Scripture Text & Audio Narration Copyright Compliance

## Core Principle
The Selah Scripture Audio Meditation application strictly honors and enforces all digital rights, publisher licensing terms, and narrator copyrights for all supported Bible translations and audio recordings.

---

## 1. Translation Licensing Tiers & Rights Holders

### Tier 1: Proprietary Licensed Translations (e.g., NIV)
- **Scripture Text**: The Holy Bible, New International Version® NIV® Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.® Used by Permission. All rights reserved worldwide.
- **Audio Narration**: The Listener’s Bible®: NIV® Edition Audio ℗ 2011 by Max McLean. Used by permission of Fellowship for the Performing Arts and Biblica/Zondervan.
- **Data Provider**: American Bible Society via API.Bible (`https://api.scripture.api.bible`).
- **Telemetry Obligation**: Every chapter fetch must report Fair Use Management System (FUMS) tokens to API.Bible to ensure publisher auditing, attribution transparency, and proper royalty attribution.

### Tier 2: Public Domain Scripture (e.g., BSB, WEB)
- **BSB**: Berean Standard Bible text and audio (narrated by Barry Hays) are dedicated to the public domain.
- **WEB**: World English Bible text is public domain. New Testament drama narration ℗ 2013 Hosanna / Faith Comes By Hearing.

---

## 2. Streaming vs. Offline Caching Boundaries

### Strict Restrictions on Proprietary Audio
1. **Zero Permanent Offline Caching of Proprietary Audio**:
   Under API.Bible licensing agreements, audio streams for proprietary copyrighted translations (such as the NIV Listener's Bible) must operate exclusively on an on-demand streaming basis. The application MUST NEVER cache, download to disk, or serialize proprietary audio MP3 files for permanent offline access.
2. **Offline Fallback for Proprietary Translations**:
   If the device loses internet connectivity while a proprietary translation is active, the audio engine MUST gracefully fall back to local on-device Text-to-Speech (TTS) rather than failing or serving unpermitted cached audio.

### Permitted Offline Caching
1. **Public Domain Audio (BSB & WEB)**:
   Audio recordings dedicated to the public domain (BSB narrated by Barry Hays) may be cached locally for seamless offline meditation.
2. **Text Metadata & WhisperX Alignments**:
   Word-level WhisperX timestamp alignment JSONs and structural chapter text contain zero proprietary audio bytes and may be bundled locally and cached offline for all translations to ensure instant, zero-latency karaoke highlighting.

---

## 3. Mandatory UI Attribution Requirements

Every player and reading interface in Selah must provide visible, easily accessible attribution:
1. **Player Card Subtitle**: Show full translation name, translation abbreviation, and `API.Bible` data provider badge.
2. **Visible Attribution Line**: Render a dedicated, compact attribution row beneath scripture text (e.g. `Public Domain · Narrator: Barry Hays` or `NIV® © Biblica, Inc.® · Audio ℗ Max McLean`) with an information action trigger.
3. **Licensing Modal Dialog**: Provide an interactive modal detailing:
   - Scripture text publisher & copyright notice
   - Narrator and production credits
   - API.Bible data provider & FUMS compliance statement
   - Offline vs. streaming boundary disclosure
4. **Minimal Screen Footprint**: Attribution must be visually harmonious, premium, and concise without cluttering meditation focus.
