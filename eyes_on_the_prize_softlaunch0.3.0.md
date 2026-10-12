# Eyes on the Prize: Selah v0.2.4 Soft-Launch & v0.3.0 Roadmap

> **Philosophy (37signals / Jason Fried & DHH)**: *"Build half a product, not a half-assed product."*  
> Deliver an exceptionally stable, peaceful, distraction-free Scripture audio experience that works flawlessly for early believers and testers. Defer experimental features cleanly behind Remote Config flags rather than exposing unpolished UI.

---

## 1. TL;DR
- **Status**: **READY FOR SOFT-LAUNCH (Grade B+ / 88.5%)**.
- **Test Suite**: **82/82 Unit & Widget Tests Passing Green (100%)**; `flutter analyze` reports **0 warnings / 0 lints**.
- **Audio Core**: Continuous looped Scripture meditation with lockscreen controls, silence gap reflection, and headphone disconnect safety verified on physical Google Pixel 9a.
- **Offline & Bundling**: 6 curated passages bundled with human narrator audio in BSB and WEB requiring zero API keys. 3-state AppBar badge (`Bundled` emerald, `Cached` amber, `Streaming` indigo).
- **Feedback & Ratings**: 3-face sentiment funnel (😊/😐/😞), interactive `BetterFeedback` screenshot drawing, dual Doorbell.io + Firestore backup delivery.
- **Feature Flagging**: Community feature voting is fully coded and verified, but cleanly concealed by default via Firebase Remote Config (`featureVotingEnabled: false`). Testers can opt-in via Settings -> "Show Work-in-Progress Features".

---

## 2. Executive Summary
Tonight's release focuses on putting a delightfully calm, rock-solid prototype in the hands of 12–40 early community testers and believers.

Rather than cluttering the app with half-finished social voting or complex driving UIs, we have:
1. Audited the application across 5 core categories, achieving an overall Grade **B+ (88.5%)** posted to [Issue #59](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/59).
2. Protected copyright boundaries strictly: NIV remains stream-only via API.Bible with FUMS telemetry; only public domain / permissive open translations (BSB, WEB) are bundled locally.
3. Created dedicated, tracked GitHub issues for future modules (A/B testing, Prayer mode, Memorization mode with AI recitation verification, and Meditation mode).
4. Authored comprehensive architectural guides including `README_RATINGS.md` and established GitHub Issue #77 for the project Wiki.

---

## 3. Features in Scope for Soft-Launch (v0.2.4 Candidate)

| Feature | Scope / Behavior | Verification Proof |
| :--- | :--- | :--- |
| **Curated Audio Bundling** | Matthew 11:28-30, 1 Cor 13:4-7, Romans 8:31-39, Psalm 23, Psalm 62:1-2, Colossians 1:1-2 pre-bundled in assets. Zero network needed. | `BundledAudioService`, emerald badge |
| **NIV Stream-Only Guardrail** | Live API.Bible audio streaming; zero MP3 disk persistence; polite info banner fallback on network disconnect. | `OfflineScriptureCache`, FUMS telemetry |
| **Offline Indicator** | 3 states: Emerald (`Bundled`), Amber (`Cached`), Indigo (`Streaming`). Uncluttered, informative. | `offline_indicator_test.dart` (Passed) |
| **3-Face Feedback Funnel** | Happy (😊) leads to 4-5 star rating; Neutral (😐) and Sad (😞) route privately to `selahfeedback` hub to prevent public review skew. | `emoji_feedback_dialog.dart`, PR #63 |
| **BetterFeedback Drawing** | Users can draw directly on screen captures to highlight audio or text alignment bugs. | `feedback_service.dart`, `README_RATINGS.md` |
| **Gated Feature Voting** | Defaulted to `OFF` via Firebase Remote Config. Settings toggle allows opt-in preview without public clutter. | `SettingsBottomSheet`, PR #78 |
| **Lockscreen Background Audio** | `just_audio_background` foreground service, media notification controls, `becomingNoisy` headphone disconnect pause. | Pixel 9a walking test ([#6](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/6)) |

---

## 4. Mini-Milestones Table

| ID | Title & Scope | Start Time (UTC) | End Time (UTC) | Status | Proof / Artifact |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **M1** | Pixel 9a Physical Device Walking Test | 2026-10-11 22:30 | 2026-10-11 23:45 | **COMPLETE** | Grade B+ posted to [#6](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/6#issuecomment-6118279363) |
| **M2** | Soft-Launch Readiness Scorecard Audit | 2026-10-12 00:20 | 2026-10-12 00:42 | **COMPLETE** | Grade B+ (88.5%) posted to [#59](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/59#issuecomment-6118465399) |
| **M3** | Clarify Offline Indicator (Bundled vs Cached) | 2026-10-11 23:50 | 2026-10-12 00:15 | **COMPLETE** | `fix/#65-clarify-offline-indicator` (`0e42fcb`) |
| **M4** | Gate Feature Voting behind Remote Config | 2026-10-12 00:30 | 2026-10-12 00:50 | **COMPLETE** | PR [#78](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/78) merged |
| **M5** | Add Settings WIP Features Opt-in Switch | 2026-10-12 00:45 | 2026-10-12 00:50 | **COMPLETE** | `settings_bottom_sheet.dart` (`b5df9d1`) |
| **M6** | Ratings Documentation (`README_RATINGS.md`) | 2026-10-12 00:35 | 2026-10-12 00:48 | **COMPLETE** | `README_RATINGS.md` in repository root |
| **M7** | Create Wiki Issue & Documentation Architecture | 2026-10-12 00:44 | 2026-10-12 00:45 | **COMPLETE** | GitHub Issue [#77](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/77) |
| **M8** | A/B Experiment Setup (Remote Config Knobs) | 2026-10-12 00:49 | 2026-10-12 00:50 | **COMPLETE** | GitHub Issue [#79](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/79) |
| **M9** | Modularization Sub-Issues (Prayer, Memorization, Meditation) | 2026-10-12 00:50 | 2026-10-12 00:51 | **COMPLETE** | GitHub Issues [#80](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/80), [#81](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/81), [#82](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/82) |
| **M10** | Dynamic Knob A/B Telemetry & Event Dispatch | 2026-10-12 00:52 | 2026-10-12 00:59 | **COMPLETE** | PR [#84](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/84) merged |
| **M11** | Merge Working Release Branch to Main via MCP | 2026-10-12 00:51 | 2026-10-12 00:52 | **COMPLETE** | PR [#63](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/63) merged (`693f059`) |
| **M12** | Production Web Build & Firebase Deploy | 2026-10-12 01:00 | 2026-10-12 01:02 | **COMPLETE** | Live at [`https://selahword.web.app`](https://selahword.web.app) |
| **M13** | Release Tag & CHANGELOG Documentation | 2026-10-12 01:02 | 2026-10-12 01:03 | **COMPLETE** | Tag `v0.2.4`, PR [#85](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/85) merged |

---

## 5. Where We Are Right Now & Next 3 to 12 Priorities

### Where We Are Right Now
- The codebase is clean, robust, and 100% green (`82/82` tests pass, `0` analyze errors).
- Feature voting and experimental features are hidden behind Firebase Remote Config and local settings opt-in.
- The 3-face feedback dialog and BetterFeedback drawing pipeline are wired and documented.
- All future exploration items requested by the user are formally cataloged in GitHub issues.

### Next 3 to 12 Tactical Actions
1. **Action 1**: Merge working branch `feat/#55-3-face-feedback-funnel` (PR #63) into `main` using `github` MCP `merge_pull_request`.
2. **Action 2**: Switch to dedicated ticket branch `feat/#71-integrate-firebase-analytics` for Issue #71.
3. **Action 3**: Add `firebase_core` and `firebase_analytics` cleanly with cross-platform initialization (iOS, Android, Web).
4. **Action 4**: Connect repetition knob analytics event `select_knob_value` to support A/B Experiment #79.
5. **Action 5**: Verify event dispatching with Firebase MCP server.
6. **Action 6**: Run `flutter test` and `flutter analyze` to guarantee zero regressions.
7. **Action 7**: Push branch and open PR for Issue #71 via `github` MCP.
8. **Action 8**: Merge Issue #71 PR into `main`.
9. **Action 9**: Execute production web build: `flutter build web --release`.
10. **Action 10**: Deploy to Firebase Web Hosting: `firebase deploy --only hosting`.
11. **Action 11**: Create git release tag `v0.2.4` and verify live web deployment at `https://selahword.web.app`.
12. **Action 12**: Update `11oct_2026_selah_session.md` with final commit hashes, deployment URLs, and verification logs.

---

## 6. FAQ

### Q1: Why is Feature Voting hidden if the code is finished?
**A**: Following 37signals' product philosophy, an unpolished or unmoderated community voting board detracts from the app's spiritual stillness. The code is complete, tested, and works with Firestore REST, but keeping it off by default (`featureVotingEnabled: false`) lets early testers focus on audio meditation. Power testers can still enable it in Settings under "Show Work-in-Progress Features".

### Q2: Why did Aptabase show 0 sessions on the dashboard today?
**A**: In debug mode and during local testing, `--dart-define=APTABASE_KEY=...` is omitted. By design (Zero Plaintext Secrets Rule), `kAptabaseAppKey` defaults to `REDACTED`, which prevents test and debug noise from polluting production analytics. CI/CD injects the live key on release builds.

### Q3: Why can't we cache NIV audio for offline listening?
**A**: Biblica / Zondervan copyright terms strictly prohibit unauthorized local file storage and redistribution of proprietary NIV recordings. Public domain translations (BSB, WEB) are safe to bundle and cache offline; NIV audio is streamed on-demand via API.Bible with mandatory FUMS telemetry.

### Q4: How does the 3-face feedback funnel protect our ratings?
**A**: Happy users (😊) are encouraged to leave a public 5-star review, while Neutral (😐) and Sad (😞) users are gently routed to a private in-app feedback dialog (Doorbell.io + Firestore). This gives us constructive critique directly without hurting public store visibility.

---

## 7. Troubleshooting Guide

| Error Signature | Root Cause | Diagnostic Check | Mitigation Step |
| :--- | :--- | :--- | :--- |
| `DioException [bad response]: status code 400` in Remote Config | Firestore REST URL called during Flutter widget test environment where network is stubbed. | Inspect Talker logs for `[REMOTE CONFIG]`. | Service automatically catches and falls back to offline embedded defaults. Harmless in tests. |
| `pumpAndSettle timed out` in widget tests | `CircularProgressIndicator` running an infinite spinning animation in the tree. | Look for `CircularProgressIndicator` in test stack trace. | Use `tester.pump(duration)` instead of unbounded `pumpAndSettle()`. |
| Audio abruptly pauses when unplugging headphones | Normal Android system behavior (`AUDIO_BECOMING_NOISY`). | Check audio player state after unplugging. | Expected design. Audio pauses gracefully to avoid sudden loud phone speaker broadcast in public. |
| Duplicate import warning in `flutter analyze` | Library imported twice in the same `.dart` file. | Run `flutter analyze`. | Remove extraneous duplicate import statement. |

---

## 8. Useful Links & GitHub Issues
- **Soft-Launch Release Checklist & Scorecard**: [Issue #59](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/59)
- **Pixel 9a Physical Walking Test**: [Issue #6](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/6)
- **Driving Mode & Bluetooth Audio**: [Issue #66](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/66)
- **Remote Config Feature Gating**: [Issue #67](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/67) & [PR #78](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/78)
- **Offline Mode Deepening**: [Issue #68](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/68)
- **Copyright & YouVersion Platform**: [Issue #69](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/69)
- **On-Device Neural TTS (Kokoro)**: [Issue #70](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/70)
- **Firebase Analytics Clean Integration**: [Issue #71](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/71)
- **Background Fetch Evaluation**: [Issue #72](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/72)
- **FCM & In-App Messaging**: [Issue #73](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/73)
- **Collections & Shareable URLs**: [Issue #74](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/74)
- **Modularization Epic v0.4.0**: [Issue #75](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/75)
- **In-App Feedback Benchmarking**: [Issue #76](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/76)
- **GitHub Wiki Architecture**: [Issue #77](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/77)
- **A/B Experiment (Repetition Knobs)**: [Issue #79](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/79)
- **Prayer Mode Module**: [Issue #80](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/80)
- **Memorization Mode Module**: [Issue #81](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/81)
- **Meditation Mode Module**: [Issue #82](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/82)

---

## 9. Appendix A: Hardware, Commits & Telemetry Verification
- **Test Devices**: Google Pixel 9a (`56091JEBF14039` & `58221JEBF20835`, Android 17 / API 37); iOS Simulator (`iPhone 16 Pro`, iOS 18.2).
- **Target Web URL**: `https://selahword.web.app` (Firebase Web Hosting).
- **Git Commit (`feat/#67`)**: `a9f9c4d` (merged into working branch as `b5df9d1`).
- **Test Suite Results**:
  ```text
  00:09 +82: All tests passed!
  Analyzing selah_prototype_audio_13sep2026...
  No issues found! (ran in 6.7s)
  ```

---

## 10. Appendix B: Granular Step-by-Step Tactical Log
1. **Step B.1**: Inspected walking log and posted on-device validation comment on Issue #6 (Grade B+).
2. **Step B.2**: Fixed offline indicator ambiguity in `offline_indicator.dart`; distinguished emerald `Bundled` from amber `Cached` and indigo `Streaming`.
3. **Step B.3**: Added `featureVotingEnabled: false` default to `RemoteConfigService`.
4. **Step B.4**: Connected `BetterFeedback` screenshot drawing to `EmojiFeedbackDialog` with multi-channel telemetry.
5. **Step B.5**: Added `showWorkInProgressFeatures` to `UserPreferences` and interactive switch in `SettingsBottomSheet`.
6. **Step B.6**: Resolved test failure in `corinthians_13_verse_4_widget_test.dart` by ensuring "Request" action is always available on uncurated passage searches.
7. **Step B.7**: Resolved infinite animation timeout in `widget_test.dart` by replacing `pumpAndSettle()` with timed pump.
8. **Step B.8**: Fixed duplicate import warning in `chapter_player_screen.dart:26:8`.
9. **Step B.9**: Verified full test suite (`82/82` passed) and static analysis (`0` issues).
10. **Step B.10**: Created ticket branches, opened PR #78, and merged via GitHub MCP.
11. **Step B.11**: Created GitHub Wiki issue #77 and documented ADR outline.
12. **Step B.12**: Created A/B Experiment issue #79 with Firebase Remote Config and Analytics configuration.
13. **Step B.13**: Created child issues #80 (Prayer Mode), #81 (Memorization Mode), and #82 (Meditation Mode) under Modularization Epic #75.
