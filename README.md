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

---

## 🚀 Running & Building the App

### 1. Web (Local Development & Chrome)
```bash
flutter run -d chrome \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```

### 2. Android (Physical Device or Emulator)
```bash
flutter run -d <android-device-id> \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```

### 3. iOS (Simulator or Physical iPhone)
```bash
flutter run -d <ios-device-id> \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```

---

## 📦 Production Release Commands

### Web Release Build
```bash
flutter build web --release \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```
*Output: `build/web/`*

### Firebase Hosting Deployment
```bash
firebase deploy --only hosting
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```
*Output: `build/app/outputs/bundle/release/app-release.aab`*

### iOS Archive / IPA (App Store & TestFlight)
```bash
flutter build ipa --release \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```
*Output: `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/selah.ipa`*

---

## 🛠️ IDE Run Configurations

### VS Code
A launch configuration is pre-configured in `.vscode/launch.json`. Ensure `API_BIBLE_KEY` and `APTABASE_KEY` are exported in your terminal environment or `.zshrc`.

### Android Studio / IntelliJ
Add `--dart-define=API_BIBLE_KEY=$API_BIBLE_KEY --dart-define=APTABASE_KEY=$APTABASE_KEY` to your Run/Debug Configuration's **Additional run args**.

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

## 📄 License & Credits
- **Audio & Scripture**: [API.Bible](https://api.bible) (BSB & WEB translations).
- **Text-to-Speech**: `flutter_tts` engine with custom peaceful pacing.
- **Architecture**: CodeWithAndrea Feature-First Riverpod 3.0 layout.
