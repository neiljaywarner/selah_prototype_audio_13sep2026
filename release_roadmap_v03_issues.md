# Selah Scripture Audio Meditation — Release Roadmap & GitHub Issues

This roadmap defines milestones **v0.2.1**, **v0.2.2**, and **v0.3**, alongside actionable GitHub Issues and repository migration guidelines.

---

## 🚀 Version Milestones

### [v0.2.1] — Telemetry & Remote Config Polish
- **Target**: Immediate post-v0.2 stabilization.
- **Goals**: Finalize Firebase Remote Config dynamic feature flags, activate PostHog analytics provider alongside Aptabase and Firebase Analytics, and verify app installation logs.

### [v0.2.2] — Feedback, Themes & Predefined Presets
- **Target**: UX refinement.
- **Goals**: Enhance diagnostic log export with the new email/GitHub issue submission flow (`njwandroid+selahfeedback@gmail.com`), add light/dark theme toggle refinement, and ensure Psalm 42 & Psalm 62 stream perfectly across platforms.

### [v0.3.0] — Advanced Passage & Verse Memorization
- **Target**: Core feature expansion.
- **Goals**: Integrate Gemini Nano AI Prompt API for on-device voice memorization feedback (`gemini_free_tier_listen_to_user_talk...`), expand verse/passage search endpoints, and migrate repository to team name without `_prototype`.

---

## 📋 Recommended GitHub Issues (To Be Created via GitHub API)

### 1. Repository Rename & Migration (`v0.3`)
- **Title**: Migrate repository to team namespace without `_prototype`
- **Description**: Transfer repository ownership from personal fork to team org, update remote origin URLs, and update CI/CD workflows and Firebase Hosting site targets.
- **Labels**: `infra`, `migration`, `v0.3`

### 2. PostHog Analytics Provider Activation (`v0.2.1`)
- **Title**: Complete PostHog analytics provider integration
- **Description**: Implement event forwarding inside `PostHogAnalyticsProvider` using `posthog_flutter`, respecting privacy and unawaited dispatch rules.
- **Labels**: `analytics`, `v0.2.1`

### 3. Firebase Remote Config Feature Flags (`v0.2.1`)
- **Title**: Wire up Remote Config parameters for dynamic Bible translation defaults
- **Description**: Connect `RemoteConfigService` to control default translation (`BSB`), meditation gap duration, and featured topics dynamically.
- **Labels**: `backend`, `remote-config`, `v0.2.1`

### 4. Advanced Theme Customization (`v0.2.2`)
- **Title**: Add light mode palette and theme persistence
- **Description**: Implement fully accessible light mode theme paired with current deep indigo `#0F0E26` dark aesthetic, persisting user preference via `ScriptureUserDataRepository`.
- **Labels**: `ui`, `theming`, `v0.2.2`

### 5. AI Voice Memorization Speccing (`v0.3`)
- **Title**: Implement Gemini Nano GenAI Prompt API for verse recitation evaluation
- **Description**: Record microphone audio buffer, send to on-device Gemini Nano model, and compare user recitation against target canonical verse.
- **Labels**: `ai`, `feature`, `v0.3`
