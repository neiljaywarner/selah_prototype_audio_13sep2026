# Enhanced User Feedback & Diagnostic Log Submission Strategy

**Goal**: Provide a seamless, secure mechanism for users to submit feedback and diagnostic logs directly from **Selah**, targeting a private GitHub Issue queue with `njwandroid+selahfeedback@gmail.com` as the primary email fallback.

---

## 1. Security & Redaction Baseline

Before any diagnostic logs leave the client device, `AppLogger._sanitize(...)` automatically redacts sensitive information:
- `API_BIBLE_KEY` is scrubbed and replaced with `[REDACTED_API_KEY]`.
- `APTABASE_KEY` is scrubbed and replaced with `[REDACTED_APTABASE_KEY]`.
- User auth tokens and headers are stripped from Dio stack traces.

---

## 2. Immediate Feedback Path: Email Dispatch

For instant submission without requiring third-party authentication tokens on the client:

### Recipient Address
```
njwandroid+selahfeedback@gmail.com
```

### Pre-formatted `mailto:` URI Generator
```dart
String buildFeedbackEmailUri({
  required String userFeedback,
  required String category,
  required List<String> logs,
}) {
  final subject = Uri.encodeComponent('Selah App Feedback [$category]');
  final sanitizedLogs = logs.take(30).join('\n');
  
  final body = Uri.encodeComponent('''
User Feedback:
$userFeedback

--- App Context ---
App Version: v0.2.0
Platform: Flutter Web / Mobile

--- Diagnostic Logs ---
$sanitizedLogs
''');

  return 'mailto:njwandroid+selahfeedback@gmail.com?subject=$subject&body=$body';
}
```

---

## 3. Future Roadmap: Private GitHub Issues API Integration

To route bug reports and diagnostic traces directly into private GitHub repo issues (`selah_prototype_audio_13sep2026`):

```
┌─────────────────┐       ┌────────────────────────┐       ┌──────────────────────┐
│  Selah App Client│ ───>  │ Secure Cloud Gateway   │ ───>  │ Private GitHub Repo  │
│  (Sanitized Logs)│       │ (Firebase / Supabase)  │       │ (Issues Board)       │
└─────────────────┘       └────────────────────────┘       └──────────────────────┘
```

### Direct GitHub Issue API Payload Specification
- **Endpoint**: `POST /repos/{owner}/{repo}/issues`
- **Headers**:
  ```http
  Authorization: Bearer <GITHUB_PAT_IN_CLOUD_SECRET>
  Accept: application/vnd.github.v3+json
  ```
- **JSON Request Body**:
  ```json
  {
    "title": "[User Report] Audio Stream Timeout - BSB JHN.1",
    "body": "### User Feedback\n> Audio paused unexpectedly after verse 5.\n\n### App Version\n`v0.2.0`\n\n### Sanitized Logs\n```text\nℹ️ [SELAH INFO] 23:54:02: Fetching narrator stream for JHN.1 (aadc8a2f4bdb467b-01) from API.Bible...\n🔴 [SELAH ERROR] 23:54:14: Dio network notice: connectTimeout\n```",
    "labels": ["user-feedback", "triage", "v0.2"]
  }
  ```

---

## 4. Implementation Steps in Selah

1. **Diagnostic Drawer**: In `chapter_player_screen.dart`, add a "Send Logs & Feedback" button to the Diagnostic Console drawer.
2. **Email Trigger**: Open default mail client directed to `njwandroid+selahfeedback@gmail.com` with formatted sanitized logs.
3. **Cloud Proxy Function**: Deploy a lightweight Firebase Cloud Function or Supabase Edge Function to securely hold the GitHub Fine-Grained Personal Access Token (PAT) and create GitHub Issues automatically.
