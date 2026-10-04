# Feedback Channels & Feature Voting Strategy

Evaluation and implementation details for user feedback mechanisms in **Selah**.

---

## 1. Mechanisms Compared

| Solution | Best Use Case | Free Tier Available? | Flutter Integration Ease |
| :--- | :--- | :--- | :--- |
| **Doorbell.io** | Direct user messages, bug reports, and prayer requests delivered to email/dashboard | **Yes (Free tier)** | **Very Simple** (Lightweight 20-line REST client via `dio`) |
| **UserOrient (`userorient_flutter`)** | Public feature voting board and roadmap prioritization | **Yes (Free tier)** | **Official Flutter SDK** (`userorient_flutter`) |
| **`better_feedback` + GitHub Issues** | Detailed visual bug reports with user screenshot annotations and logs | **Yes (GitHub Free)** | **Official Flutter SDK** (`better_feedback`) submitting to private GH repo via Octokit / REST |
| **In-App Built-In Roadmap Sheet** | Zero-dependency, immediate in-app voting and direct message submission | **100% Free / Built-in** | **Already integrated in Selah v0.2!** |

---

## 2. Doorbell.io Lightweight REST Client

Doorbell.io has a simple REST endpoint requiring no third-party package:

- **Endpoint**: `POST https://doorbell.io/api/applications/{app_id}/submit?key={app_key}`
- **Headers**: `Content-Type: application/json`
- **Body**:
```json
{
  "message": "User feedback text here",
  "email": "user@example.com",
  "sentiment": "positive",
  "properties": {
    "app_version": "0.2.0",
    "platform": "web"
  }
}
```

In Selah, this is implemented in `lib/src/core/feedback/feedback_service.dart`. To activate your account, pass your keys at runtime:
```bash
--dart-define=DOORBELL_APP_ID="YOUR_APP_ID" \
--dart-define=DOORBELL_API_KEY="YOUR_API_KEY"
```

---

## 3. Better Feedback + GitHub Issues Integration (v0.2.1+)

For visual bug reporting with on-screen drawing:
1. Wrap root widget with `BetterFeedback(child: SelahApp())`.
2. On feedback submission, serialize the screenshot png and post an issue to a private repository:
```bash
POST https://api.github.com/repos/{owner}/{private-repo}/issues
Authorization: Bearer GITHUB_PAT
```
3. Issue body includes annotated image, app version, logs from `AppLogger.logs`, and device info.
