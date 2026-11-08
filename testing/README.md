# 🧪 Selah Testing & Quality Assurance Runbook

Welcome to the definitive testing and QA guide for **Selah: Scripture Audio Meditation**. This document outlines our multi-tiered test harness architecture designed to achieve **95.5%+ soft-launch production readiness (Solid Grade A)** across Android, iOS, and Web.

---

## 📑 Table of Contents
1. [Quality Target: Why 95%+ Matters](#-quality-target-why-95-matters)
2. [Testing Architecture Matrix](#-testing-architecture-matrix)
3. [Harness 1: Marionette Driver & VM Service Testing](#-harness-1-marionette-driver--vm-service-testing)
4. [Harness 2: Maestro Mobile End-to-End Automation](#-harness-2-maestro-mobile-end-to-end-automation)
5. [Harness 3: Patrol Native + Flutter Integration Testing](#-harness-3-patrol-native--flutter-integration-testing)
6. [Harness 4: Fast Unit & Widget Test Suite](#-harness-4-fast-unit--widget-test-suite)
7. [Pre-Release Checklist & Run Commands](#-pre-release-checklist--run-commands)

---

## 🎯 Quality Target: Why 95%+ Matters

In our Session Log ([`12oct_2026_selah_session.md`](../12oct_2026_selah_session.md)), Selah progressed from **82.0% (Grade B-)** to **92.5% (Grade A-)**. 

### Should we settle for 93%–94% or push to 95%+?
**We strongly recommend driving to 95.5%+ (Solid Grade A)** before opening to broader external beta testers. Here is why:

| Area | 92%–93% (Good Enough) | 95%+ (Solid Grade A Release) |
| :--- | :--- | :--- |
| **User Immersion** | Audio plays, but timing clipping or subtle UI stutter can break contemplative prayer. | Verse audio boundaries are acoustically calibrated to silence pauses (WhisperX); zero clipping. |
| **Feedback Funnel** | Confusing 4/5 star branches; user exposed to email copy clipboard workarounds. | 1-click peaceful sentiments (Loving it, Suggestion, Needs work); multi-channel background telemetry. |
| **Automation** | Tests run on desktop emulator; physical device requires manual checking. | Tri-harness automation (**Marionette**, **Maestro**, **Patrol**) validates physical device screens, audio output, and insets. |
| **Regressions** | Changes in one screen can introduce keyboard or layout overflows unexpectedly. | Mandatory `flutter analyze` (0 issues) and 96+ widget tests with 100% pass guarantee. |

---

## 🏗️ Testing Architecture Matrix

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
│test (96) │     │hot-reload,    │               │screenshots,   │   │lifecycle, OS  │
│Fast CI   │     │state inspect  │               │E2E journeys   │   │permissions    │
└──────────┘     └───────────────┘               └───────────────┘   └───────────────┘
```

---

## 🕹️ Harness 1: Marionette Driver & VM Service Testing

Marionette allows Antigravity and automated test runners to communicate directly with Flutter's rendering tree and VM Service over WebSockets.

### 1. Starting the Application for Marionette
Run the app in debug mode on your connected device (e.g. Google Pixel 9a):
```bash
flutter run -d 58221JEBF20835
```
Observe the VM Service WebSocket URI output:
```
A Dart VM Service on Pixel 9a is available at:
ws://127.0.0.1:56352/eKlYWJNsJYU=/ws
```

### 2. Available Marionette MCP Tools (20 Tools)
When interacting through Antigravity IDE:
* **`connect`**: `call_mcp_tool(ServerName='marionette', ToolName='connect', Arguments={'uri': '<ws_uri>'})`
* **`take_screenshots`**: Captures high-res uncompressed PNG frames directly from the Flutter engine.
* **`get_interactive_elements`**: Discovers all interactive widgets, their bounding boxes, keys, and text labels.
* **`tap`**: Simulates tap gestures by `key`, `text`, or screen coordinates `{x, y}`.
* **`enter_text`**: Enters text into focused text fields.
* **`scroll_to`**: Scrolls until a targeted element is fully in view.
* **`hot_reload` / `hot_restart`**: Triggers proactive Flutter code reloading without restarting the process.
* **`press_back_button`**: Simulates Android system back navigation.

### 3. Standalone Marionette CLI Runner
You can run our automated VM Service sanity suite with zero external dependencies:
```bash
dart run scripts/marionette_smoke_suite.dart ws://127.0.0.1:<PORT>/<TOKEN>/ws
```

---

## 📱 Harness 2: Maestro Mobile End-to-End Automation

[Maestro](https://maestro.mobile.dev/) provides declarative YAML-based E2E UI automation that tests Selah as an authentic user on physical devices and emulators.

### 1. Installation
```bash
curl -fsSL "https://get.maestro.mobile.dev" | bash
export PATH="$PATH":"$HOME/.maestro/bin"
```

### 2. Available Flows in `.maestro/`
| Flow File | Purpose | Key Assertions |
| :--- | :--- | :--- |
| [`.maestro/smoke_test.yaml`](../.maestro/smoke_test.yaml) | Full smoke test | Header branding, scripture excerpt load, passage switching, screenshot proof. |
| [`.maestro/feedback_streamlined_flow.yaml`](../.maestro/feedback_streamlined_flow.yaml) | Streamlined feedback | More Options menu, "Prayer & Feedback" tap, sentiment selection, reflection entry. |
| [`.maestro/tested_passages_flow.yaml`](../.maestro/tested_passages_flow.yaml) | Tested passages modal | "+ More (12)" sheet tap, Psalm 23 / Rom 8 selection, passage playback load. |
| [`.maestro/pixel9a_smoke.yaml`](../.maestro/pixel9a_smoke.yaml) | Fast physical device smoke | Rapid healthcheck and screenshot verification for Google Pixel 9a. |
| [`.maestro/share_passage_web.yaml`](../.maestro/share_passage_web.yaml) | Share link on local Flutter web | `?ref=1+Cor+13:4-7` lands and can play. `NotABook 99:1` shows a friendly error on the player. |
| [`.maestro/share_passage_android.yaml`](../.maestro/share_passage_android.yaml) | Share sheet on Android | Player and My Passages share `1 Cor 13:4-7`. The sheet shows the reference link, not the verse. |

### 3. Running Maestro Flows
```bash
# Run the core smoke test flow
maestro test .maestro/smoke_test.yaml

# Run the streamlined feedback flow
maestro test .maestro/feedback_streamlined_flow.yaml

# Run the tested passages sheet flow
maestro test .maestro/tested_passages_flow.yaml
```

### Share a passage (web + Android)

Serve this branch locally. The flow is pinned to `http://127.0.0.1:8091`. Do not point it at selahword.web.app.

```bash
# flutter run stays in the foreground. Wait until it prints that the app
# is being served, then run Maestro in another terminal.
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8091
maestro test --headless --screen-size 1200x2200 .maestro/share_passage_web.yaml
```

The Android flow drives the real share sheet. Install the normal debug app (not the Patrol test bundle):

```bash
flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
maestro test .maestro/share_passage_android.yaml
```

`flutter install` can select an older `app-release.apk`. Install the debug apk from the build you just made. Maestro uses the booted emulator (on this machine, AVD `maestro` / `emulator-5554`).

---

## 🛡️ Harness 3: Patrol Native + Flutter Integration Testing

[Patrol](https://patrol.leancode.co/) is our advanced Flutter integration test framework that bridges Dart tests with native Android and iOS platform features (handling system permission dialogs, notifications, and lockscreen controls).

### 1. Installation
Patrol is already configured in `pubspec.yaml` (`patrol: ^4.10.0`, `patrol_finders: ^3.6.0`). To install the CLI:
```bash
dart pub global activate patrol_cli
```

### 2. Available Patrol Integration Tests
* [`integration_test/patrol_test.dart`](../integration_test/patrol_test.dart): End-to-end test using `patrolTest` verifying header branding, passage chip selection, scripture excerpt rendering, translation switching (BSB/WEB), and Prayer & Feedback dialog interaction.
* [`integration_test/app_test.dart`](../integration_test/app_test.dart): Standard Flutter integration test verifying search autocomplete, settings modals, 1 Cor 13 timing feedback bar, and AppBar options.
* [`patrol_test/share_passage_test.dart`](../patrol_test/share_passage_test.dart): Share-link landing, friendly error for a bad `?ref=`, and the reference-only payload from the player and from My Passages. Android instrumentation is `MainActivityTest` with `PatrolJUnitRunner`.

### 3. Running Patrol Tests
```bash
# Run on connected Android device via Patrol CLI
patrol test -t integration_test/patrol_test.dart

# Share a passage (issue #240). Requires a booted Android emulator.
patrol test -t patrol_test/share_passage_test.dart -d emulator-5554

# Or run via standard Flutter test runner
flutter test integration_test/app_test.dart -d 58221JEBF20835
```

### 4. Patrol MCP Server (`patrol_mcp`)
We configure LeanCode's official **Patrol MCP** server directly in `.agents/mcp_config.json` via package `patrol_mcp`:
```json
"patrol": {
  "command": "dart",
  "args": ["run", "patrol_mcp"],
  "env": {
    "PROJECT_ROOT": ".",
    "PATROL_FLAGS": "",
    "SHOW_TERMINAL": "false"
  }
}
```
* **Interactive Test Control**: Orchestrates live `patrol develop` hot-restart sessions.
* **Autonomous Error Debugging**: Automatically captures failure screenshots and streams terminal logs back to the AI assistant.

---

## ⚡ Harness 4: Fast Unit & Widget Test Suite

Our primary regression safety net runs 96 unit and widget tests in under 15 seconds.

```bash
# Run all unit and widget tests
flutter test

# Run a specific widget test (e.g. Feedback Dialog)
flutter test test/widget/emoji_feedback_dialog_test.dart

# Run 1 Cor 13:4 acoustic boundary tests
flutter test test/unit/corinthians_13_verse_4_test.dart
```

All 96 tests pass with 100% coverage across core audio playback, verse timestamps, karaoke highlighting, feedback routing, and copyright attributions.

### Share a passage (issue #240) — `bdd_widget_test`

Gherkin lives in `test/features/share_a_passage.feature`. Step definitions live in `test/features/step/`. `bdd_widget_test` generates `test/features/share_a_passage_test.dart`, which `flutter test` runs in CI.

```bash
# Regenerate the widget test from the feature file after editing Gherkin
dart run build_runner build --delete-conflicting-outputs

# Run the share scenarios and the URL/payload unit tests
flutter test test/features/share_a_passage_test.dart test/unit/passage_share_link_test.dart
```

The scenarios cover sharing the playing passage, sharing from My Passages, opening a valid link while signed out, and a friendly error for a broken reference. They assert the payload contains `?ref=1+Cor+13:4-7` and does not contain the verse body. `test/features/receive_shared_passage.feature` covers opening `?ref=Psalm+62:5-7` on the BSB path so the curated 62:1–2 wording is not substituted.

The native iOS, Android, and web share sheets cannot open inside a widget test. `PlatformPassageShareLauncher` is that thin device boundary: it copies the link and passes the same reference-only message to `share_plus`. A unit test captures that message with a fake share platform. Widget scenarios replace the launcher and assert the payload.

Maestro and Patrol cover the same behaviors on a device. Maestro web opens the real `?ref=` URL. Maestro on Android taps share and reads the share sheet. Patrol, on the emulator, asserts the player landed on `1 Cor 13:4-7`, that a bad reference stays on the player, and that the payload's reference is `1 Cor 13:4-7`, the URL contains `?ref=1+Cor+13:4-7` and starts with the GitHub Pages origin, and the message contains that reference, URL, and attribution. It also checks the message does not contain the verse fragments `love is patient` and `love is kind`. It does not compare the whole share message to one exact string.

```bash
# flutter run stays in the foreground. Wait until it prints that the app
# is being served, then run Maestro in another terminal.
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8091
maestro test --headless --screen-size 1200x2200 .maestro/share_passage_web.yaml

flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
maestro test .maestro/share_passage_android.yaml

patrol test -t patrol_test/share_passage_test.dart -d emulator-5554
```

The web flow's `url:` header sends it to desktop Chromium. Without that header, Maestro opens the link in the emulator's Chrome. iOS Simulator is not part of this run: this Mac has Command Line Tools only, so `simctl` is unavailable. The Android share sheet is what Maestro drives. Patrol's `_expectReferenceOnly` checks those reference, URL, attribution, and verse-fragment assertions. It is not an exact match of the full share message.

---

## 📋 Pre-Release Checklist & Run Commands

Before distributing any new build to Firebase App Distribution or merging to `main`:

```bash
# 1. Static Analysis (Zero warnings required)
flutter analyze

# 2. Complete Unit & Widget Test Suite (96/96 Green)
flutter test

# 3. Integration & Smoke Tests (On connected device)
maestro test .maestro/smoke_test.yaml

# 4. Verify No Plaintext Secrets in Staged Diffs
git diff --staged
```

---
*Maintained by the Selah Engineering Team. Soli Deo Gloria.*
