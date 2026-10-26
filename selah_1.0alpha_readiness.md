# Selah 1.0 Alpha Readiness Runbook & Verification Matrix

> **Target Release:** Selah Scripture Audio Meditation `v0.4.1+52`  
> **Deployment Targets:** Production Web (`https://selahword.web.app`), Firebase Preview Channel, Android Release (Firebase App Distribution `core-testers`).  
> **Last Updated:** 2026-10-25 18:49:00 UTC-5  
> **Primary Policy:** ESV 1.0 Soft Launch (Crossway David Cochran Heath human narrator audio, zero TTS for ESV, experimental translations strictly gated behind developer feature flag).

---

## 1. TL;DR
- **Root Cause of Live Prod Web TTS & NIV Banner:**
  1. Build `--dart-define` previously preserved shell single-quotes (`'Token <key>'`), resulting in 401 Unauthorized from `api.esv.org`.
  2. Browser XHR cannot read `302 Location` headers across cross-origin requests (`audio.esv.org` lacks permissive CORS headers for XHR), causing `fetchPassageAudioUrl` to return `null` on Web.
  3. Falling back to `https://api.esv.org/v3/passage/audio/?q=...` failed on Web because HTML5 `<audio>` ignores custom HTTP headers.
  4. Audio playback failures on Web fell through to `API.Bible` / `BundledAudioService` where `translation.isLicensed == true` triggered the proprietary `"NIV audio stream is proprietary..."` notice and invoked `_switchToTtsFallback`.
  5. `firebase.json` previously cached `main.dart.js`, `index.html`, and `version.json` for 3600 seconds.
- **The Fix:**
  - Token sanitization strips single/double quotes from all `--dart-define` inputs (`api_constants.dart`).
  - Web resolves direct, headerless CDN streaming URLs (`https://audio.esv.org/hw/<query>.mp3`) which play natively in HTML5 `<audio>`.
  - Ironclad TTS forbidden invariant in `chapter_player_notifier.dart` prevents TTS from ever executing when ESV or soft launch mode is active.
  - Hardcoded NIV fallback notice now strictly requires `translation == BibleTranslation.niv`.
  - Cache-busting headers configured in `firebase.json` for bootstrap/app JS files.
  - Version bumped to `0.4.1+52`.

---

## 2. Executive Summary
Selah 1.0 Alpha focuses on delivering a contemplative, loopable Scripture meditation experience using Crossway's ESV human narrator audio (David Cochran Heath). The soft-launch experience enforces:
1. Pure human narration with zero robotic Text-to-Speech (TTS) fallbacks for ESV passages.
2. Complete seclusion of unfinished/proprietary API.Bible streams (NIV, BSB, WEB) and Translation Shuffle behind the `experimentalApiBibleNarrator` feature flag.
3. Rapid cache invalidation on production Web.

---

## 3. Mini-Milestones & Progress Tracker

| Milestone | Scope / Objective | Owner / Model | Status | Verification Proof |
| :--- | :--- | :--- | :--- | :--- |
| **M1: Forensic Root Cause Analysis** | Trace live prod web TTS / NIV bug across notifier & network logs | Lead Agent | ✅ DONE | Traced 5 smoking guns: single quotes, XHR CORS, `<audio>` headers, fallthrough, cache |
| **M2: Sanitization & Direct CDN URLs** | Strip shell quotes; resolve `audio.esv.org/hw/` for Web | Lead Agent | ✅ DONE | `test/unit/esv_api_client_test.dart` passing (17/17 tests) |
| **M3: Riverpod Rebuild & TTS Guardrails** | Fix Riverpod `late` reuse; ironclad `_isEsvModeActive` guards | Lead Agent | ✅ DONE | `esv_zero_tts_and_feature_flag_sociable_test.dart` |
| **M4: Web Cache-Control Headers** | Configure `no-cache` for JS/HTML in `firebase.json`; bump to `0.4.1+52` | Lead Agent | ✅ DONE | `firebase.json`, `pubspec.yaml` updated |
| **M5: Web & Android Build & Deploy** | Build release web & APK; deploy to Firebase Hosting & App Dist | Flash Subagent / Lead | ⏳ WIP | Pending test completion & deployment execution |
| **M6: End-to-End QA & Issue Sync** | Verify live `https://selahword.web.app` & Android with Marionette/Maestro | Flash Subagent | 📋 NEXT | Screenshots & GitHub issue filing |

---

## 4. Troubleshooting Runbook

### Issue A: Web plays TTS or shows "NIV audio stream" notice
- **Symptoms:** User taps play on `1 Cor 13:4-7` on Web and hears robot voice or sees NIV disclaimer.
- **Root Cause:** Token had stray quotes or fallback reached API.Bible logic.
- **Fix:** Inspect `build/web/main.dart.js` for `"Token '"`. Ensure `sanitizeEnvSecret` is used and `_isEsvModeActive` intercepts fallbacks.

### Issue B: Browser XHR CORS error on `audio.esv.org`
- **Symptoms:** Console error `Access to XMLHttpRequest at 'https://audio.esv.org/...' from origin 'https://selahword.web.app' has been blocked by CORS policy`.
- **Root Cause:** Making a `Dio.get` request to audio URLs on Web.
- **Fix:** On Web (`kIsWeb`), use `EsvApiClient.directHwAudioUrl(query)` directly in `AudioSource.uri(..., headers: null)`. Do not make XHR requests for audio redirects.

### Issue C: `LateInitializationError: Field '_audioPlayer' has already been initialized`
- **Symptoms:** Toggling developer features in settings crashes the app.
- **Root Cause:** `ChapterPlayerNotifier` declared `late final AudioPlayer _audioPlayer;` inside a class that rebuilds in Riverpod 3.
- **Fix:** Changed declarations to `late AudioPlayer _audioPlayer;` without `final`.

---

## 5. Playbook for Less Expensive Models (Flash / Flash-Lite Subagents)
When running verification or documentation tasks with low-cost models:
1. **Never run unsandboxed (`BypassSandbox: true`) background commands in subagents.**
2. Use `dart roots` and `dart analyze_files` via the Dart MCP server for immediate, prompt-free lint validation.
3. Use GitHub MCP tools (`list_issues`, `issue_write`, `add_issue_comment`) for all issue tracking.
4. Execute test runs through the centralized runner script:
   ```bash
   python3 scripts/release_and_deploy.py test <test_path>
   ```

---

## 6. Frequently Asked Questions (FAQ)

**Q: Can ESV audio ever use TTS?**  
A: No. In Selah 1.0 soft-launch, ESV audio is strictly human narrator (David Cochran Heath). If network drops, the app halts and surfaces a clean retry option.

**Q: Why was NIV mentioned when listening to ESV?**  
A: An earlier condition checked `translation.isLicensed` (which is true for both ESV and NIV) on failure branches, triggering legacy Biblica notices. This has been restricted to `translation == BibleTranslation.niv`.

**Q: How do testers receive the updated Android APK?**  
A: Testers in `core-testers` (`njwandroid@gmail.com, neilwarner@gmail.com`) receive automated notifications via Firebase App Distribution upon running `python3 scripts/release_and_deploy.py distribute-apk`.

---

## 7. Appendix & Command Cheatsheet

```bash
# Run unit & sociable test suite
python3 scripts/release_and_deploy.py test test/unit/esv_zero_tts_and_feature_flag_sociable_test.dart

# Build Web with sanitized definitions and bundle verification
python3 scripts/release_and_deploy.py build-web

# Deploy to Firebase Preview Channel & Production Web
python3 scripts/release_and_deploy.py deploy-web

# Compile and upload Android Release APK to core-testers
python3 scripts/release_and_deploy.py distribute-apk
```
