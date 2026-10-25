# Selah Scripture Audio Meditation 🕊️

**Selah** is a modern, contemplative Scripture audio meditation application built with **Flutter**, **Riverpod 3.0**, and **API.Bible**.

---

## 🌟 Key Features in Release v0.2.0

- **Feature-First Modular Architecture**: Organized under `lib/src/` with domain, application, presentation, and core layers following CodeWithAndrea's guidelines.
- **Smart Audio Routing Engine**:
  - **Berean Standard Bible (BSB)**: Human narrator audio across all 66 Old & New Testament books (`aadc8a2f4bdb467b-01`).
  - **World English Bible (WEB)**: Human drama narrator audio across all 27 New Testament books (`105a06b6146d11e7-01`).
  - **WEB Old Testament**: Automatic fallback to peaceful Text-to-Speech (TTS) (API.Bible does not offer WEB OT audio streams).
  - **Single Verse Queries**: Interactive word-by-word TTS with real-time karaoke highlighting.
- **Canonical Bible Validation (`BibleCanon`)**: Validates 66 canonical books (39 OT, 27 NT) and exact chapter boundaries.
- **Interactive Chapter Picker Modal**: Filter and jump to any canonical book and valid chapter.
- **Curated Topic Tabs**: Dedicated meditation categories (**Hope**, **Faith**, **Peace**, **Comfort**, **Strength**) with quick-launch chapter chips.
- **Multi-Provider Analytics**: Asynchronous event dispatch via `unawaited(...)` supporting Aptabase (`aptabase_flutter`), Firebase Analytics, and PostHog.
- **Community Feedback & Roadmap**: Feature voting board and direct user feedback submission.

---

## 🔑 Environment Variables & API Keys

Selah requires API keys injected at compile-time via `--dart-define`:

- `API_BIBLE_KEY`: API.Bible access key for fetching REST audio streams and text passages.
- `APTABASE_KEY`: App analytics key for Aptabase telemetry.
- `ESV_API_KEY`: Crossway ESV API token for single-verse and verse-range lookup. Chapter audio stays on API.Bible. Export it from `~/.zshrc` or a GitHub Actions secret named `ESV_API_KEY`. Never commit the value.

Crossway's free tier allows 5,000 queries/day, 1,000/hour, and 60/minute, with at most 500 verses per request. A range such as `1 Cor 13:4-7` is one request per verse. Ranges longer than 60 verses are not split, so a pasted chapter cannot spend the whole minute budget.

---

## 🚀 Running & Building the App

### 1. Web (Local Development & Chrome)
```bash
flutter run -d chrome \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY \
  --dart-define=ESV_API_KEY=$ESV_API_KEY
```

### 2. Android (Physical Device or Emulator)
```bash
flutter run -d <android-device-id> \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY \
  --dart-define=ESV_API_KEY=$ESV_API_KEY
```

### 3. iOS (Simulator or Physical iPhone)
```bash
flutter run -d <ios-device-id> \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY \
  --dart-define=ESV_API_KEY=$ESV_API_KEY
```

---

## 📦 Production Release Commands

### Web Release Build
```bash
flutter build web --release \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY \
  --dart-define=ESV_API_KEY=$ESV_API_KEY
```
*Output: `build/web/`*

### Firebase Hosting Preview Channels (Staging)
Test and preview web changes on ephemeral, temporary URLs without impacting live production users:
```bash
firebase hosting:channel:deploy preview_name
```
See the complete [Preview Channels Guide](README_PREVIEW_CHANNELS.md) and [Wiki Entry](docs/wiki/Firebase-Hosting-Preview-Channels.md).

### Firebase Hosting Production Deployment
```bash
firebase deploy --only hosting
```
*Live at: [https://selahword.web.app](https://selahword.web.app)*

### Codemagic CI/CD Build & Deploy
Automated Web PWA and Android APK deployment pipelines are documented in the [Codemagic Deployment Guide](docs/CODEMAGIC_DEPLOYMENT.md), outlining build environments, code signing, and secret groups.



### Android App Bundle (Google Play)
```bash
flutter build appbundle --release \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY \
  --dart-define=ESV_API_KEY=$ESV_API_KEY
```
*Output: `build/app/outputs/bundle/release/app-release.aab`*

### iOS Archive / IPA (App Store & TestFlight)
```bash
flutter build ipa --release \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY \
  --dart-define=ESV_API_KEY=$ESV_API_KEY
```
*Output: `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/selah.ipa`*

---

## 🛠️ IDE Run Configurations

### VS Code
A launch configuration is pre-configured in `.vscode/launch.json`. Ensure `API_BIBLE_KEY`, `APTABASE_KEY`, and `ESV_API_KEY` are exported in your terminal environment or `.zshrc`. GitHub Actions preview builds read the same names from repository secrets.

### Android Studio / IntelliJ
Add `--dart-define=API_BIBLE_KEY=$API_BIBLE_KEY --dart-define=APTABASE_KEY=$APTABASE_KEY --dart-define=ESV_API_KEY=$ESV_API_KEY` to your Run/Debug Configuration's **Additional run args**.

---

## 🧪 Testing

Run the full unit test suite:
```bash
flutter test
```

All 12 core unit tests verify:
- `BibleCanon` canonical book and chapter bounds.
- `BibleReferenceParser` search autocomplete and chapter clamping.
- `AnalyticsWrapper` unawaited event dispatch.
- `SelahApp` UI component smoke testing.

---

## 🗺️ Strategic Roadmap
- **[v0.3.0 Release Roadmap](ROADMAP_v0.3.0.md)**: Walking and driving mode with lockscreen controls, curated verse excerpts (`PassageExcerpt`), community voting, direct Doorbell.io feedback, and ESV narrator integration.

---

## ⚠️ Git & Workflow Rules (Strictly Enforced)
- **Zero Direct Pushes to `main`**: `main` is protected. All changes MUST be developed on dedicated branches and merged via Pull Requests audited by the PR Triage Skill.
- **Ticket-Driven Development**: Every task, bug fix, or feature MUST be tracked by an active GitHub issue (`#<ticket-id>`).
- **Ticket-Named Branches**: Create branches using the ticket pattern: `feat/#<ticket-id>-<slug>` or `fix/#<ticket-id>-<slug>`.
- **Conventional Commits with Ticket Scope**: Commit messages MUST include the ticket number in their scope:
  - `feat(#<ticket>): <imperative summary>`
  - `fix(#<ticket>): <imperative summary>`
  - `docs(#<ticket>): <imperative summary>`
  - `test(#<ticket>): <imperative summary>`

---

## 🤖 AI Skills & Automation Runbooks
Custom AI developer workflows and skills located in `.agents/skills/`:
- **[PR CodeRabbit Triage & Merge Skill](.agents/skills/pr-coderabbit-triage-and-merge/README.md)**: Automated runbook and CLI scripts (`triage_pr_comments.py`, `defer_comments_to_issues.py`) to systematically audit review findings, resolve critical blockers, defer non-critical items into tracked GitHub issues, and safely merge pull requests.

---

## 📄 License & Credits
- **Audio & Scripture**: [API.Bible](https://api.bible) (BSB & WEB translations).
- **Text-to-Speech**: `flutter_tts` engine with custom peaceful pacing.
- **Architecture**: CodeWithAndrea Feature-First Riverpod 3.0 layout.
