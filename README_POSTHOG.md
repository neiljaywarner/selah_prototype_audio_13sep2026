# PostHog Analytics: Technical Runbook & Operational Architecture

## 1. Overview
**PostHog** serves as the product analytics and telemetry engine for Selah Scripture Audio Meditation alongside Aptabase and Firebase Analytics. It provides session tracking, custom event pipelines, exception monitoring, and cohort funnel analysis.

---

## 2. Configuration & Zero-Secret Architecture

### Environment Variables & Dart Defines
PostHog keys are **never** hardcoded into the repository. They are supplied at build time via `--dart-define`:
```bash
flutter run \
  --dart-define=POSTHOG_KEY=$POSTHOG_KEY \
  --dart-define=POSTHOG_HOST=https://us.i.posthog.com
```

In Dart source (`lib/src/core/constants/api_constants.dart` & `lib/main.dart`):
```dart
const String kPostHogApiKey = String.fromEnvironment(
  'POSTHOG_KEY',
  defaultValue: String.fromEnvironment('POSTHOG_MEMVERSE_API_KEY', defaultValue: 'REDACTED'),
);
const String kPostHogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);
```
- If the key is omitted or equals `'REDACTED'`, `PostHogAnalyticsProvider` runs in **safe mock mode**, logging events to local `debugPrint` without attempting network requests.

---

## 3. PostHog Model Context Protocol (MCP) Server Setup
To allow autonomous AI agents and IDE tools to query live telemetry and dashboard insights directly, configure the PostHog MCP server in `.agents/mcp_config.json`:

```json
{
  "mcpServers": {
    "posthog": {
      "command": "npx",
      "args": ["-y", "@posthog/mcp-server"],
      "env": {
        "POSTHOG_API_KEY": "${POSTHOG_PERSONAL_API_KEY}",
        "POSTHOG_HOST": "https://us.i.posthog.com"
      }
    }
  }
}
```

---

## 4. Standard Event Taxonomy

| Event Name | Trigger Location | Payload Properties | Purpose |
| :--- | :--- | :--- | :--- |
| `app_started` | `main.dart` | `platform`, `build_mode`, `version` | Baseline session count & platform distribution |
| `play_chapter` | `ChapterPlayerNotifier` | `translation`, `book`, `chapter`, `audio_mode` | Tracks which Scripture chapters are listened to |
| `play_excerpt` | `ChapterPlayerNotifier` | `reference`, `translation`, `start_ms`, `end_ms` | Monitors curated passage meditation engagement |
| `repetition_tick`| `ChapterPlayerNotifier` | `current_iteration`, `target_repetitions`, `is_gap` | Measures meditation loop progress |
| `feedback_submitted` | Feedback dialog | `sentiment`, `has_comment` | Captures user satisfaction |
| `$exception` | Global error handler | `$exception_type`, `$exception_message`, `stack_trace` | Automatic exception telemetry |

---

## 5. Privacy & Data Protection Safeguards
1. **Zero Personally Identifiable Information (PII)**:
   - No names, email addresses, or phone numbers are ever tracked.
   - User identity uses an anonymous ephemeral UUID.
2. **Audio Streams are Untracked**:
   - Proprietary audio binaries (NIV) are never transmitted to PostHog; only chapter reference metadata (`MAT.11`) is recorded.
3. **GDPR & CCPA Compliant**:
   - Host defaults to privacy-hardened US or EU endpoints (`us.i.posthog.com` / `eu.i.posthog.com`).

---

## 6. Strategic Tickets Roadmap
- **POC (#41)**: Connect PostHog MCP server and verify initial ping.
- **MVP (#42)**: Core meditation user journey metrics (completion rates & drop-offs).
- **EXPLORE (#43)**: Advanced session replay, automated cohorts, and retention experiments.
