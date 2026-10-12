# Selah Scripture Audio Meditation — Release Checklist

This release checklist defines the mandatory quality gates, security audits, and platform verification steps before any release (e.g. `v0.2.4` / `v0.3.0` soft-launch, or `v0.4.0`) is deployed to production or Firebase Hosting.

---

## 1. Automated Quality & Static Analysis Gates
- [ ] **Static Analysis**: `flutter analyze` runs with **0 issues** found.
- [ ] **Test Suite**: `flutter test` passes **100% green** across all unit and widget tests.
- [ ] **Timestamp Regression Test**: `test/unit/curated_timestamps_validation_test.dart` passes:
  - All verse boundaries are strictly monotonic (`startMs < endMs`).
  - Speaking rates are within human bounds (1.0 to 5.2 words per second).
  - Matthew 11:28 starts at $\ge$ 250,000ms (BSB) / $\ge$ 235,000ms (WEB).
  - Romans 8:31 starts at $\ge$ 295,000ms (BSB) / $\ge$ 250,000ms (WEB).

---

## 2. Security & Zero-Secret Audit
- [ ] **Git History Audit**: Run `git log -S "API_BIBLE_KEY"` or inspect `git diff --staged` to verify no plaintext API keys, passwords, or tokens are introduced.
- [ ] **Environment Resolution**: All API keys (`API_BIBLE_KEY`, `APTABASE_KEY`, `POSTHOG_KEY`, `DOORBELL_API_KEY`) resolve safely via `String.fromEnvironment(..., defaultValue: 'REDACTED')`.
- [ ] **Ignored Files**: Confirm `google-services.json`, `GoogleService-Info.plist`, `.env*`, and keystores remain in `.gitignore`.

---

## 3. Copyright & Legal Licensing Verification
- [ ] **Visible Publisher Attribution**:
  - Player Card and Fullscreen player render visible attribution for API.Bible and publisher copyright.
  - Tapping the attribution banner displays the full `_LicensingAttributionSheet` modal.
- [ ] **Offline Caching Gate**:
  - Open translations (**BSB**, **WEB**) have bundled offline timestamp JSONs.
  - Proprietary translations (**NIV**) are NEVER cached or downloaded to disk; streaming is strictly ephemeral at runtime.

---

## 4. Multi-Platform Verification

### A. Android (Google Pixel 9a, Physical Device)
- [ ] Native ExoPlayer initializes without crashes.
- [ ] Curated chips (1 Cor 13, Matt 11, Rom 8, Psalm 23) play with sub-millisecond clipping.
- [ ] Repetition loops seek cleanly to `Duration.zero` without `Playlist must contain 1 UriAudioSource` exception.
- [ ] 4-second reflection gap pauses before repeating.

### B. Apple iOS (iOS Simulator)
- [ ] Audio session initializes and plays through system output.
- [ ] Layout conforms to safe area boundaries on notch / Dynamic Island devices.
- [ ] Touch targets meet accessibility minimums ($\ge 48 \times 48$ dp).

### C. Chrome Web PWA
- [ ] Web audio context resumes on first user tap.
- [ ] Responsive layout adapts smoothly from desktop window to mobile browser viewport.
- [ ] PWA manifest and service worker load without console errors.

---

## 5. Deployment Procedure: Firebase Web Hosting

1. **Build Release Web Bundle**:
   ```bash
   flutter build web --release \
     --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
     --dart-define=APTABASE_KEY=$APTABASE_KEY \
     --dart-define=POSTHOG_KEY=$POSTHOG_KEY
   ```
2. **Verify Local Bundle**:
   Verify that `build/web/index.html` and `build/web/main.dart.js` exist and have non-zero sizes.
3. **Deploy to Firebase Hosting**:
   ```bash
   firebase deploy --only hosting
   ```
4. **Smoke Test Live URL**:
   Open the deployed Firebase Hosting URL in Chrome, verify audio playback on Matthew 11:28–30, and confirm karaoke verse highlighting.
