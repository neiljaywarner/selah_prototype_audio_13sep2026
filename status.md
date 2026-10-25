# Selah Scripture Audio — ESV Human Narrator & 1.0 Soft Launch Status Report

**Document Date:** October 25, 2026  
**Primary Workspace:** `/Users/neil/selah/selah_prototype_audio_13sep2026`  
**Git Branch:** `main` (Synced to `origin/main`)  
**Verified Hardware:** Google Pixel 9a (`58221JEBF20835`), Chrome PWA  
**Audio Source:** Crossway ESV API (`api.esv.org` → `audio.esv.org`) — David Cochran Heath narration  

---

## 1. TL;DR

- **ESV Human Narrator "Just Works":** All verse lookups and passage meditations (including single verses like `John 11:35` and ranges like `1 Cor 13:4–7` and `1 Peter 5:7–9`) stream authentic human audio by **David Cochran Heath** directly from Crossway (`audio.esv.org`).
- **Zero TTS Fallback for ESV:** Text-to-speech fallback has been completely removed for ESV. The player badge displays `🎙️ Human Narrator`.
- **Clean 1.0 Soft Launch UI:** The BSB, WEB, and NIV translations, along with the translation shuffle button (`🔀`), have been placed safely behind the developer preview flag (`experimentalApiBibleNarrator`). The soft launch interface is strictly ESV-only, uncluttered, and displays no intrusive disclaimer boxes.
- **Automated Maestro Verification:** The Maestro test flow (`.maestro/esv_verse_lookup_flow.yaml`) executed with **100% pass rate (exit code 0)** on physical hardware (Pixel 9a), validating `John 11:35`, `1 Corinthians 13:4–7`, and `1 Peter 5:7–9`.
- **Merged to Main:** Pull Request #217 was squash-merged into `main` (`dd87f41`) and the follow-up soft launch UI refinement committed in `094ae0c`.

---

## 2. Summary of Work & Milestones

| Mini-Milestone | Start Time | End Time | Status | Artifacts / Proof |
| :--- | :--- | :--- | :--- | :--- |
| **M1: Audio Redirection & Header Fix** | 15:10 | 15:25 | ✅ Completed | Resolved Crossway 302 redirect (`api.esv.org` → `audio.esv.org/hw/mq/...`) to prevent ExoPlayer HTTP 403 header stripping. |
| **M2: TTS Removal for ESV** | 15:25 | 15:35 | ✅ Completed | Stripped all fallback TTS logic for ESV; added `_spokenText` copyright guard. |
| **M3: Curated Passage Catalog Expansion** | 15:35 | 15:42 | ✅ Completed | Added `1 Peter 5:7–9` to `kFeaturedChapters` and `kCuratedExcerpts`. |
| **M4: PR #217 CI Workflow Fix & Merge** | 15:42 | 15:53 | ✅ Completed | Updated Flutter to `3.47.x`; guarded preview deployment step; merged PR #217 into `main` (`dd87f41`). |
| **M5: 1.0 Soft Launch UI Refinement** | 15:55 | 16:07 | ✅ Completed | Placed BSB/WEB/NIV and Shuffle behind preview flag; removed disclaimer banners; set subtitle to `ESV • Crossway`. |
| **M6: Marionette Visual Verification** | 16:05 | 16:08 | ✅ Completed | Connected via Dart VM Service to Pixel 9a; captured `pixel9a_esv_soft_launch_verified.png`. |
| **M7: Maestro End-to-End Test Suite** | 16:08 | 16:11 | ✅ Completed | Executed `.maestro/esv_verse_lookup_flow.yaml` on Pixel 9a with exit code 0; generated 3 screenshot proofs. |

---

## 3. Explanation of the Preview Channel URL

### Why Did the Preview URL Mention an Asterisk (`*`)?
When GitHub Actions deploys a PR preview channel using `FirebaseExtended/action-hosting-deploy@v0`, Firebase Hosting creates a temporary, uniquely isolated preview channel URL following this naming scheme:
```
https://<site-name>--<channel-id>-<random-hash>.web.app
```
For example:
- **Project Site:** `selahword`
- **Channel ID:** `pr-217`
- **Random Hash:** e.g., `a15pcecz`
- **Actual Live URL:** `https://selahword--pr-217-a15pcecz.web.app`

In documentation and workflow descriptions, `https://selahwordapp--pr-217-*.web.app` uses the asterisk `*` purely as a **wildcard placeholder** for that 8-character random hash generated at deploy time, rather than a literal asterisk character.

### Current Hosting Channel Status:
- The production / stable web app is hosted at: **`https://selahword.web.app`**
- Firebase Preview deployment requires the repo secret `FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP` to be added in GitHub Repository Settings. Until configured, the CI workflow step is safely guarded with `if: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP != '' }}` to guarantee clean CI builds without blocking pull requests.

---

## 4. Maestro Verification Results on Physical Pixel 9a

Maestro ran locally on attached hardware (`58221JEBF20835`) executing `.maestro/esv_verse_lookup_flow.yaml`:

```
Running on 58221JEBF20835
  > Flow: esv_verse_lookup_flow
    ✅ Launch app "com.example.selah_prototype_audio_13sep2026"
    ✅ Wait for animation to end
    ✅ Assert that ".*SELAH.*" is visible
    ✅ Tap on "John 1"
    ✅ Erase text
    ✅ Input text John 11:35
    ✅ Tap on "Play"
    ✅ Assert that ".*\(ESV\).*" is visible
    ✅ Take screenshot docs/artifacts/screenshots/esv_john_11_35
    ✅ Erase text
    ✅ Input text 1 Cor 13:4-7
    ✅ Tap on "Play"
    ✅ Assert that ".*13:4.*" is visible
    ✅ Assert that ".*\(ESV\).*" is visible
    ✅ Take screenshot docs/artifacts/screenshots/esv_1_cor_13_4_7
    ✅ Erase text
    ✅ Input text 1 Peter 5:7-9
    ✅ Tap on "Play"
    ✅ Assert that ".*\(ESV\).*" is visible
    ✅ Take screenshot docs/artifacts/screenshots/esv_1_peter_5_7_9
```

### Visual Verification Artifacts:
- **John 11:35 (Single Verse):** [`docs/artifacts/screenshots/esv_john_11_35.png`](file:///Users/neil/selah/selah_prototype_audio_13sep2026/docs/artifacts/screenshots/esv_john_11_35.png)
- **1 Corinthians 13:4–7 (Curated Range):** [`docs/artifacts/screenshots/esv_1_cor_13_4_7.png`](file:///Users/neil/selah/selah_prototype_audio_13sep2026/docs/artifacts/screenshots/esv_1_cor_13_4_7.png)
- **1 Peter 5:7–9 (Featured Excerpt):** [`docs/artifacts/screenshots/esv_1_peter_5_7_9.png`](file:///Users/neil/selah/selah_prototype_audio_13sep2026/docs/artifacts/screenshots/esv_1_peter_5_7_9.png)
- **Pixel 9a Soft Launch UI Live:** [`docs/artifacts/screenshots/pixel9a_esv_soft_launch_verified.png`](file:///Users/neil/selah/selah_prototype_audio_13sep2026/docs/artifacts/screenshots/pixel9a_esv_soft_launch_verified.png)

---

## 5. Frequently Asked Questions (FAQ)

### Q1: Why did the app previously show "ESV audio stream error: (0) Source error"?
**Answer:** ExoPlayer on Android follows strict HTTP security specs: when `https://api.esv.org/v3/passage/audio/?q=...` responded with a `302 Found` redirecting to `https://audio.esv.org/...`, ExoPlayer dropped the `Authorization: Token ...` header across cross-origin redirect domains. Crossway's audio CDN then rejected the unauthenticated request with HTTP 403 Forbidden.  
**Fix:** `EsvApiClient.fetchPassageAudioUrl` pre-resolves the redirect to extract the direct MP3 URL first. ExoPlayer then connects directly to `audio.esv.org` with the Authorization header intact.

### Q2: How do I re-enable the other 3 Bible translations (BSB, WEB, NIV) and Translation Shuffle?
**Answer:** In the app, tap the **Settings** gear icon in the top right. Scroll to the bottom and enable the toggle **"Preview: API.Bible narrator translations"**. This restores the segmented selector (`ESV | BSB | WEB | NIV`) and the `🔀` shuffle button across playback repetitions.

### Q3: How do I test or build with the ESV API key without committing secrets?
**Answer:** Never commit `ESV_API_KEY`. It is stored securely in `~/.zshrc`. When building or running, pass it as a Dart compile-time define:
```bash
python3 scripts/build_and_install.py
```
Or manually:
```bash
flutter run -d 58221JEBF20835 --dart-define=ESV_API_KEY=$(grep 'ESV_API_KEY=' ~/.zshrc | cut -d'=' -f2 | tr -d '"')
```

---

## 6. Troubleshooting Guide

| Symptom | Cause | Solution |
| :--- | :--- | :--- |
| **Maestro fails with `ClassNotFoundException`** | Standalone sandbox isolates `~/.maestro/lib` JARs. | Run Maestro outside sandbox using `/Users/neil/.maestro/bin/maestro --device <id> test <flow>`. |
| **Marionette cannot connect to VM service** | ADB port forwarding not active on host. | Run `adb forward tcp:<port> tcp:<port>` using the port printed in `logcat -d \| grep "listening on"`. |
| **Firebase deploy fails with `Missing service account`** | `FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP` secret absent in GitHub repo settings. | The step is guarded in `pr_preview_channel.yml`. To enable automated preview deploy, add the service account JSON secret under Repo Settings → Secrets → Actions. |
| **Audio stops after 1 loop** | Repetition count set to 1. | Tap the **Loop** chip on the player to cycle between `Loop 1 of 3`, `Loop 1 of 7`, or `Infinite Loop`. |

---

## 7. Appendix: MCP Tool Manifests

### Maestro MCP Server Tools
- **`list_devices`**: Enumerates locally connected mobile devices, emulators, and Chromium instances.
- **`inspect_screen`**: Returns accessibility/view tree hierarchy of the running application.
- **`run`**: Executes local Maestro flow YAML or folders against target devices.
- **`take_screenshot`**: Captures screen frame as an image artifact.
- **`cheat_sheet`**: Quick syntax reference for assertion regex, input actions, and conditions.
- **`open_maestro_viewer`**: Launches interactive visual inspector studio.
- **`run_on_cloud` / `get_cloud_run_status` / `describe_cloud_run`**: Cloud runner tools.

### GitHub MCP Server Tools
- **`pull_request_read`**: Reads PR metadata, mergeability status, diff stats, and review comments.
- **`merge_pull_request`**: Merges pull requests (squash, merge, or rebase).
- **`get_job_logs`**: Fetches raw console output from GitHub Actions workflow runs.
- **`actions_list` / `actions_get` / `actions_run_trigger`**: Dispatches and monitors CI/CD pipelines.
- **`create_pull_request` / `update_pull_request` / `create_branch`**: Branch & PR management.

### Marionette MCP Server Tools
- **`connect`**: Establishes Dart VM Service WebSocket link (`ws://127.0.0.1:<port>/...`).
- **`take_screenshots`**: High-fidelity in-engine viewport capture.
- **`get_interactive_elements`**: Discovers render tree widgets, keys, text labels, and bounds.
- **`tap` / `enter_text` / `scroll_to`**: Programmatic widget interaction and input.
- **`hot_reload` / `hot_restart`**: Instant stateful code reload and reset during development.
