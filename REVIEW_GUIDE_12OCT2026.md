# 🕊️ Executive & Product Review Guide (Session 12 Oct 2026)

> **Triad Cross-Links**:  
> - 🎟️ **GitHub Review Issue**: [Issue #92](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/92)  
> - 📖 **Official GitHub Wiki**: [Review Guide for Tomorrow Night](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/wiki/Review-Guide-for-Tomorrow-Night)  
> - 🌐 **Staging Web Preview**: [https://selahword--preview-v0-3-1-a15pcecz.web.app](https://selahword--preview-v0-3-1-a15pcecz.web.app)  

---

## 📌 Executive Summary

Tonight's session achieved the critical milestones required for our **v0.4.0 Public Soft Launch**:
1. **Production Safety Guaranteed**: Live meditators on `https://selahword.web.app` are protected. All testing now operates on isolated Firebase Hosting preview channels (`preview-v0-3-1`).
2. **NIV "Airplane Mode" WTF Fixed**: Resolved Issue #89 and merged PR #90 (`51678d2`). Curated verse excerpts route to calm Text-to-Speech (TTS) with clear Biblica streaming notices.
3. **Private User Feedback Hub Receptive**: Verified private triage hub [njwandroid/selahfeedback](https://github.com/njwandroid/selahfeedback) with Issue #1. Users can draw directly on screen captures, and sensitive prayers remain completely confidential.
4. **Zero Plaintext Secrets**: The GitHub feedback token is injected at runtime via Firebase Remote Config template `v2`. Zero credentials in git history.
5. **Quality & Test Automation**: **85/85 tests pass green** (`flutter test`), 0 issues on `flutter analyze`. Automated pre-flight scanner script (`scripts/preview_channel_precheck.py`) guards against regressions.
6. **Community Wiki Published**: Clean, non-technical Home, Product & Ministry Home, and Engineering Home deployed live to [GitHub Wiki](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/wiki).

---

## 💛 Non-Technical & Believer Review Guide
*For Neil, friends, family, and brothers & sisters in Christ reviewing the app tomorrow night:*

### 1. Test Audio Meditation Experience
- Open the [Staging Preview Link](https://selahword--preview-v0-3-1-a15pcecz.web.app) on your mobile phone or laptop.
- Tap any curated passage chip:
  - **1 Cor 13:4–7** (*Love is patient, love is kind...*)
  - **Matthew 11:28–30** (*Come to Me, all who are weary...*)
  - **Romans 8:31–39** (*If God is for us, who can be against us?...*)
  - **Psalm 23** (*The Lord is my shepherd...*)
- Listen to the human drama narration. Notice the peaceful pacing and lack of harsh cuts.
- Tap the **Repetition Knob** (1x, 3x, 7x, ∞) to let the Scripture repeat with a gentle contemplative silence gap between cycles.

### 2. Test Feedback & Drawing on Screenshots
- Tap the overflow menu (three dots in the top right) -> **Feedback & Reflection**.
- Choose how you feel:
  - **😊 Loving it!** (Promoter)
  - **😐 It is okay** (Constructive feedback)
  - **😞 Needs work** (Private help)
- Tap **"Draw on Screenshot & Send"**. Use your finger or mouse to draw a note or arrow on the app screen.
- Tap Submit: Notice how your thoughts are sent privately to Neil's confidential triage area without cluttering public trackers.

### 3. Verify the NIV Experience
- Open the translation selector and choose **NIV**.
- Notice that instead of a confusing "Offline / Airplane Mode" error banner, Selah displays a courteous notice explaining Biblica licensing terms and smoothly begins peaceful narration.

---

## 🛠️ Technical Engineering Review Guide
*For Neil and core developers:*

### 1. Security & Credentials
- Run `git log -S "gho_"` or `git log -S "AIza"`: zero hits in repository.
- Firebase Remote Config parameter `github_feedback_token` verified in template `v2`.
- Fallbacks in Dart code strictly adhere to `String.fromEnvironment('KEY', defaultValue: 'REDACTED')`.

### 2. Git Governance & Convention
- Zero direct pushes to `main`.
- Hotfix `v0.3.1` landed via squash merge on PR #90.
- All commits follow `feat(#<ticket>): ...`, `fix(#<ticket>): ...`, or `docs(#<ticket>): ...`.
- `git push origin master` strictly quarantined to standalone `selah_prototype_audio_13sep2026.wiki.git`.

### 3. Preview Automation & Smoke Testing
- Pre-flight WTF scanner: `python3 scripts/preview_channel_precheck.py`.
- Maestro preview smoke test flow: `.maestro/web_preview_smoke.yaml`.
- Automated PR workflow template: `.github/workflows/pr_preview_channel.yml`.

### 4. Telemetry Parity
- Web GA4 tag active: `G-7LFS54TTFM`.
- Custom dimensions attached to every event: `k_debug_mode` (`true`/`false`) and `marionette_driving` (`true`/`false`).
- Native Android debug mode enabled on Pixel 9a (`debug.firebase.analytics.app`).
