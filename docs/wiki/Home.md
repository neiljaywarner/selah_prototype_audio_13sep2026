# Welcome to the Selah Scripture Audio Meditation Wiki

Welcome to the central documentation hub for **Selah: Scripture Audio Meditation**.

## 📖 Quick Links
- **[Product Requirements & Use Cases](PRD-and-Use-Cases.md)**: Why Selah exists, who it's for, and core user stories.
- **[Architecture Decision Records (ADRs)](Architecture-Decision-Records.md)**: Technical rationale behind zero-server audio stream clipping with WhisperX.
- **[Non-Technical Guide & Next Steps](Non-Technical-Guide-and-Next-Steps.md)**: Plain-English explanation of our technology and roadmap.
- **[Marionette Automation Guide](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/blob/main/README_MARIONETTE.md)**: How automated agents and developers drive Selah via Marionette and ADB.

---

## 🌟 What makes Selah unique?
Unlike audio Bible apps that treat Scripture as a long audiobook chapter that plays once and stops:
1. **Curated Short Excerpts**: Focus on memory verses like *1 Corinthians 13:4–7*, *Matthew 11:28–30*, *Romans 8:31–39*, or *Psalm 23*.
2. **Sub-second AI Forced Alignment**: WhisperX verse-level timestamps instruct the native audio player to clip whole-chapter human narration directly on the client.
3. **Continuous Meditation Looping**: Configurable prayer/reflection pauses (3–10s) between repetitions.
4. **Translation Shuffling**: Cycles BSB, WEB, and NIV across repetitions to deepen linguistic understanding.
5. **Walking & Airplane Mode**: Full offline caching and background audio support.

---

## 🛠️ Repository & Architecture
- **Platforms**: Flutter (Chrome PWA primary, Android Pixel 9a flagship, macOS desktop).
- **Audio Stack**: `just_audio` (stream clipping & gaps) + `just_audio_background` + `flutter_tts` (offline fallback).
- **State Management**: Flutter Riverpod with immutable state notifier architecture.
- **Licensing & Fair Use**: Public Domain (BSB, WEB) bundled with offline banks; Licensed (NIV) compliant with API.Bible FUMS auditing.
