# Contributing to Selah Scripture Audio Meditation 🕊️

Welcome, and thank you for your interest in contributing to **Selah**! Whether you are fixing an audio timing issue, refining a user interface, or adding automated tests, we are deeply grateful for your service to this ministry.

---

## 🕊️ Our Mission & Development Philosophy

Selah is built to create a quiet, contemplative sanctuary where believers can pause, rest, and meditate deeply on God's Word. Every design decision, engineering abstraction, and automated test serves this purpose: **preserving peace, honoring user privacy, and eliminating distractions.**

---

## 🔒 Non-Negotiable Governance & Security Baseline

Before writing code, please review our strict workspace rules:

1. **Zero Plaintext Secrets**:
   - Under **NO circumstances** may any API keys, tokens, or credentials be committed to git.
   - Always resolve keys dynamically from environment variables or Firebase Remote Config using `String.fromEnvironment('KEY_NAME', defaultValue: 'REDACTED')`.
   - Never embed actual tokens in test files or YAML fallbacks (`${VAR:-plaintext}`).
2. **Ticket-Driven Development**:
   - Every commit and pull request must reference a tracked GitHub issue:
     - Feature branches: `feat/#<issue-id>-<slug>`
     - Bug fixes: `fix/#<issue-id>-<slug>`
     - Documentation: `docs/#<issue-id>-<slug>`
     - Chores/Refactoring: `chore/#<issue-id>-<slug>`
3. **Protected `main` Branch**:
   - Never push directly to `main` or `master`. All updates land exclusively via audited Pull Requests.
4. **Conventional Commits**:
   - Follow standard conventional commit format with ticket scope:
     `feat(#180): add BDD contributor guidelines for Marionette and Patrol`

---

## 🧪 Behavior-Driven Development (BDD) & Testing Architecture

Selah uses **Behavior-Driven Development (BDD)** to specify app behavior in human-readable Gherkin syntax before implementation.

### 1. Feature Specifications (`test/features/*_feature.txt`)
All major user flows are documented in executable feature specifications:
* [`test/features/chapter_playback_feature.txt`](test/features/chapter_playback_feature.txt): Passage looping, 4s silence gaps, and audio session lifecycle.
* [`test/features/translation_switching_feature.txt`](test/features/translation_switching_feature.txt): Seamless switching between BSB, WEB, and NIV, narrator attribution, and preference persistence.
* [`test/features/diagnostics_and_telemetry_feature.txt`](test/features/diagnostics_and_telemetry_feature.txt): Confidential feedback dispatch, automated screenshot attachments, and privacy boundaries.
* [`test/features/book_browser_feature.txt`](test/features/book_browser_feature.txt): Autocomplete search, book navigation, and unaligned verse modals.

---

## 🏗️ Tri-Harness Quality Assurance Architecture

We reject brittle coordinate-based testing. Selah enforces a tri-harness automation strategy designed to validate real user journeys across Android, iOS, and Web:

```
                      ┌───────────────────────────────────────┐
                      │          Selah Testing Matrix         │
                      └──────────────────┬────────────────────┘
                                         │
     ┌───────────────────┬───────────────┴───────────────┬───────────────────┐
     ▼                   ▼                               ▼                   ▼
┌──────────┐     ┌───────────────┐               ┌───────────────┐   ┌───────────────┐
│ Unit &   │     │  Marionette   │               │    Maestro    │   │    Patrol     │
│ Widget   │     │ (VM Service)  │               │ (Black-Box)   │   │(Native/Flutter│
├──────────┤     ├───────────────┤               ├───────────────┤   ├───────────────┤
│flutter   │     │Interactive UI,│               │Real gestures, │   │Full device    │
│test (97) │     │hot-reload,    │               │screenshots,   │   │lifecycle, OS  │
│Fast CI   │     │state inspect  │               │E2E journeys   │   │permissions    │
└──────────┘     └───────────────┘               └───────────────┘   └───────────────┘
```

### Harness 1: Marionette Driver & MCP Server
[Marionette](testing/README.md#-harness-1-marionette-driver--vm-service-testing) connects directly to Flutter's rendering tree and VM Service over WebSockets:
- **Semantic Element Discovery**: Use `get_interactive_elements` to discover keys, text labels, and bounds rather than guessing pixel coordinates.
- **Gesture Execution**: Tap elements by semantic label or key (`tap(text="Matt 11:28–30")`).
- **High-Res Uncompressed Visuals**: Capture PNG frames directly with `take_screenshots`.
- **Standalone Runner**:
  ```bash
  dart run scripts/marionette_smoke_suite.dart ws://127.0.0.1:<PORT>/<TOKEN>/ws
  ```

### Harness 2: Maestro Mobile End-to-End Automation
[Maestro](testing/README.md#-harness-2-maestro-mobile-end-to-end-automation) runs declarative YAML flows testing authentic gestures on physical devices and emulators:
```bash
# Run core smoke test
maestro test .maestro/smoke_test.yaml

# Run streamlined 1-tap feedback flow
maestro test .maestro/feedback_streamlined_flow.yaml

# Run tested passages sheet flow
maestro test .maestro/tested_passages_flow.yaml
```

### Harness 3: Patrol Native + Flutter Integration Testing
[Patrol](testing/README.md#-harness-3-patrol-native--flutter-integration-testing) bridges Dart integration tests with native OS capabilities:
- Interacts with system permission prompts and background notifications.
- Automatically captures full video recordings and screenshots upon test failure.
```bash
# Run on connected device via Patrol CLI
patrol test -t integration_test/patrol_test.dart

# Run via Flutter test runner
flutter test integration_test/app_test.dart -d <device_id>
```

---

## 🚀 Pre-PR Verification Checklist

Before opening a pull request or requesting review, verify:

```bash
# 1. Static Analysis (Must have 0 issues)
flutter analyze

# 2. Automated Test Suite (Must pass 100%)
flutter test

# 3. Verify No Secrets Staged
git diff --staged | grep -i -E "api[_-]?key|secret|token"
```

### Pull Request & Review Governance
1. Open PR referencing your issue (`Closes #<id>`).
2. Observe the mandatory **180-second CodeRabbit review buffer** before triage.
3. Every reviewer finding must receive an explicit threaded API reply (either verified fix or deferred to a tracked GitHub issue via `defer_comments_to_issues.py`).

---
*Maintained with gratitude by the Selah Community. Soli Deo Gloria.*
