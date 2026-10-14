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

### 3. Running Maestro Flows
```bash
# Run the core smoke test flow
maestro test .maestro/smoke_test.yaml

# Run the streamlined feedback flow
maestro test .maestro/feedback_streamlined_flow.yaml

# Run the tested passages sheet flow
maestro test .maestro/tested_passages_flow.yaml
```

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

### 3. Running Patrol Tests
```bash
# Run on connected Android device via Patrol CLI
patrol test -t integration_test/patrol_test.dart

# Or run via standard Flutter test runner
flutter test integration_test/app_test.dart -d 58221JEBF20835
```

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
