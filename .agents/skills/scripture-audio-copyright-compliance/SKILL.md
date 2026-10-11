---
name: scripture-audio-copyright-compliance
description: >-
  Audits, verifies, and enforces copyright compliance, publisher licensing terms,
  FUMS telemetry reporting, and visible UI attributions for Bible translations and audio streams.
---

# Scripture & Audio Copyright Compliance Skill

Use this skill whenever adding a new Bible translation, integrating audio streams, configuring offline caching, or modifying player attribution UI in Selah.

---

## 1. Compliance Checklist

Before releasing or merging code touching audio or scripture:

### A. Licensing Classification
- [ ] Determine whether the translation is **Proprietary Licensed** (e.g. NIV) or **Public Domain** (e.g. BSB).
- [ ] Record the legal copyright string and publisher permissions in `lib/src/features/meditation/domain/bible_translation.dart`.
- [ ] Credit the narrator explicitly (e.g., Barry Hays for BSB, Max McLean for NIV, Hosanna for WEB).

### B. Offline Caching Boundaries
- [ ] Verify that proprietary audio streams (NIV) are NEVER persisted or cached to disk.
- [ ] Verify that offline playback for proprietary translations gracefully routes to on-device TTS.
- [ ] Ensure WhisperX timestamp JSON alignments remain separate from proprietary audio streams.

### C. Visible UI Attribution
- [ ] Player Card displays translation name and API.Bible badge.
- [ ] Compact attribution banner is visible under scripture text.
- [ ] Tapping attribution opens the full `Scripture & Audio Licensing` modal.
- [ ] Real estate is disciplined: clean typography, subtle icon, zero intrusive banners.

### D. FUMS Telemetry
- [ ] API.Bible Fair Use Management System (FUMS) tokens are logged upon chapter load.
- [ ] Telemetry payload redacts sensitive developer keys (`AppLogger._sanitize`).

---

## 2. Verification Protocol

1. Run automated widget tests:
   ```bash
   flutter test test/widget/player_attribution_widget_test.dart
   ```
2. Verify visual rendering across mobile and web:
   ```bash
   # Android / iOS screenshot
   xcrun simctl io booted screenshot docs/artifacts/screenshots/ios_after_attribution.png
   # Web headless screenshot
   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --headless --screenshot=docs/artifacts/screenshots/chrome_after_attribution.png http://localhost:8088/
   ```
3. Inspect diff to ensure zero plain-text secrets and zero scope creep.
