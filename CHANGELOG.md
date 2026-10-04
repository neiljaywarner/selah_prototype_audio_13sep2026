# Changelog

All notable changes to the **Selah Scripture Audio Meditation** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.0] - 2026-10-04

### Added
- **CodeWithAndrea Feature-First Architecture**: Refactored monolithic `main.dart` into modular layers under `lib/src/` (`core/`, `features/meditation/domain/`, `application/`, `presentation/`).
- **Verified API.Bible Audio IDs**:
  - `aadc8a2f4bdb467b-01`: **Berean Standard Audio Bible (BSB)** — Full Bible narration across all 66 books (both Old & New Testaments).
  - `105a06b6146d11e7-01`: **World English Bible (WEB)** — Drama New Testament audio narration.
- **Smart Audio Routing Engine**:
  - Automatically routes BSB (Old & New Testament) to human spoken audio streams via API.Bible.
  - Automatically routes WEB New Testament to human spoken audio streams via API.Bible.
  - Automatically routes WEB Old Testament to peaceful Text-to-Speech (TTS) because API.Bible does not offer an Old Testament WEB audio stream.
  - Automatically routes single verse queries (e.g. `Psalm 46:10`, `John 14:27`) to TTS with word-by-word karaoke highlighting.
  - Resilient automatic fallback to TTS if audio streams fail or encounter CORS restrictions.
- **Canonical Bible Validation (`BibleCanon`)**: Full metadata for all 66 canonical books (39 OT, 27 NT) with strict chapter boundary validation (e.g. Jude: 1 ch, Psalms: 150 ch).
- **Curated Topic Tabs**: Dedicated meditation categories for **Hope**, **Faith**, **Peace**, **Comfort**, and **Strength** with quick-launch chapter chips.
- **Browse 66 Books & Chapters Dialog**: Interactive modal to filter and jump to any canonical book and validated chapter.
- **Multi-Provider Analytics Wrapper**:
  - Dispatches non-blocking, zero-latency events via `unawaited(...)` from `dart:async`.
  - **Aptabase** analytics provider (`aptabase_flutter`).
  - **Firebase Analytics** provider with Firebase Installations ID tracking.
  - **PostHog** analytics stub.
- **BaaS Abstraction Interfaces**: Created abstract `AuthRepository` and `ScriptureUserDataRepository` to isolate Firebase dependencies from UI logic and allow effortless switching.
- **Feature Roadmap & Feedback Voting Modal**:
  - In-app community voting board for upcoming features.
  - Doorbell.io direct feedback submission client with local fallback.
  - Configurable via `userorient_flutter` when `USERORIENT_KEY` is provided.
- **Firebase Hosting Pre-Configuration**: Added `firebase.json` and `.firebaserc` targeting `selahwordapp.web.app`.
- **Comprehensive Documentation Suite**:
  - [Next Version Timestamp Roadmap: timestamps_and_verses_and_passages.md](timestamps_and_verses_and_passages.md)
  - [Mobile App Store Deployment Guide: mobile_deployment.md](mobile_deployment.md)
  - [Linktree Social & Routing Strategy: linktree_plan.md](linktree_plan.md)
  - [Supabase Migration Guide: migrate_to_supabase.md](migrate_to_supabase.md)
  - [Appwrite Migration Guide: migrate_to_appwrite.md](migrate_to_appwrite.md)
  - [Flutter Flavors Configuration Guide: use_flavors.md](use_flavors.md)
  - [Feedback Channels Guide: feedback_mechanism.md](feedback_mechanism.md)
  - [Gemini Audio Memorization Specification: gemini_free_tier_listen_to_user_talk_and_see_if_they_said_it_right_feature.md](gemini_free_tier_listen_to_user_talk_and_see_if_they_said_it_right_feature.md)

### Changed
- Replaced deprecated color methods (`withOpacity`) with precision-preserving `.withValues(alpha: ...)`.
- Replaced deprecated `activeColor` with `activeThumbColor`.
- Improved dark aesthetic with deep indigo `#0F0E26` and gold amber `#FBBF24` palette.

---

## [0.1.0] - Baseline (Main Branch)

### Added
- Initial Riverpod 3.0 Scripture meditation prototype.
- Curated Scripture presets (Psalm 46:10, John 14:27, Colossians 1:9-12).
- Free verse text lookup via `bible-api.com`.
- Speech synthesis engine via `flutter_tts` with custom peaceful pacing (speech rate 0.38, pitch 0.95).
- Word-by-word karaoke text highlighting via TTS progress handler.
- Repetition controls (1x, 3x, 7x, ∞) and silent reflection gaps (2s, 4s, 7s, 12s).
- Session timer option (5m, 10m, 15m).
- Architectural roadmap card for FCBH Bible Brain integration.
