# Selah Scripture Audio Meditation: Ratings & Feedback Architecture (v0.2.4)

> *"Listen to advice and accept discipline, and at the end you will be counted among the wise."* — Proverbs 19:20

This document explains Selah's community feedback and rating system. It includes both a **Non-Technical Guide** for believers, testers, and product stewards, and a **Technical Reference** for engineers and AI agents querying metrics via the Firebase MCP server.

---

## 1. Non-Technical Guide: The Believer Feedback Experience

### Why We Use a 3-Face + Star Rating Funnel
Public App Store reviews can make or break a ministry app before it matures. If an early prototype drops audio on a walk, a frustrated user might leave a 1-star review on Google Play or the iOS App Store that stays there forever.

Selah uses a disciplined, compassionate **3-Face Funnel**:

```
                  ┌───────────────────────────────┐
                  │ How is your meditation in     │
                  │            Selah?             │
                  └──────────────┬────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
      😊 Happy               😐 Neutral                😞 Sad
  (4–5 Star Rating)       (3 Star Rating)        (1–2 Star Rating)
         │                       │                       │
         ▼                       ▼                       ▼
 [Public Praise Path]    [Private Triage]        [Private Triage]
  Encourages App Store    Direct developer note   Urgent bug/frustration
  review & gratitude      "What can we add?"      routed straight to Neil
```

1. **😊 Happy (4–5 Stars)**:
   - Celebrates God's Word working in their prayer time.
   - Prompts the user to leave a review on the App Store / Google Play and praise God.
2. **😐 Neutral (3 Stars)**:
   - Recognizes that something fell short or a feature is missing.
   - Gently routes to a private reflection box: *"What could we improve or add?"*
3. **😞 Sad (1–2 Stars)**:
   - Acknowledges frustration or a playback bug.
   - Bypasses public review prompts and funnels directly to Neil's private triage inbox (`neilwarner+selah@gmail.com` and `njwandroid/selahfeedback`).

### Visual Screenshot Feedback (`BetterFeedback`)
Believers can also tap **"Draw on Screenshot"** to circle bugs, highlight missing words, or visually show formatting issues directly on their phone screen.

---

## 2. Technical Reference: Data Pipelines & Schema

### Multi-Channel Feedback Destination Overview
Every rating and reflection is routed across 4 independent, resilient pipelines:

| Destination | Purpose | Storage / Location |
| :--- | :--- | :--- |
| **Cloud Firestore** | Primary persistent database | `selahwordapp` collection `user_feedback` |
| **Firebase Analytics** | Real-time usage & NPS aggregates | Events `feedback_submitted`, `better_feedback_submitted` |
| **Doorbell.io REST** | Dedicated customer feedback inbox | Doorbell App ID configured via CI/CD |
| **Private GitHub Triage** | Developer bug tracking | `https://github.com/njwandroid/selahfeedback` |

---

### Firestore Document Schema (`user_feedback`)
Each entry in `projects/selahwordapp/databases/(default)/documents/user_feedback` follows this schema:

```json
{
  "rating": 5,
  "emoji": "😊",
  "face": "happy",
  "message": "The Barry Hays narration of 1 Cor 13 brings so much peace to my evening walks.",
  "email": "user@example.com",
  "nps": 10,
  "platform": "android",
  "appVersion": "0.2.4",
  "deviceModel": "Pixel 9a",
  "createdAt": "2026-10-12T05:30:00.000Z"
}
```

---

## 3. Querying Ratings with Firebase MCP Server

AI agents and developers can inspect ratings and user feedback directly using the **Firebase MCP Server**:

### A. List Feedback Collections
```json
{
  "ServerName": "firebase",
  "ToolName": "firestore_list_collections",
  "Arguments": {
    "projectId": "selahwordapp"
  }
}
```

### B. Query Recent Star Ratings & Sentiment
```json
{
  "ServerName": "firebase",
  "ToolName": "firestore_query_collection",
  "Arguments": {
    "projectId": "selahwordapp",
    "collection_path": "user_feedback",
    "order": {
      "orderBy": "createdAt",
      "orderByDirection": "DESCENDING"
    },
    "limit": 20
  }
}
```

### C. Calculate Net Promoter Score (NPS)
From the returned documents:
- **Promoters**: `nps >= 9` (Rating 5 / Happy)
- **Passives**: `nps == 7 || nps == 8` (Rating 3–4 / Neutral)
- **Detractors**: `nps <= 6` (Rating 1–2 / Sad)
$$\text{NPS} = \% \text{Promoters} - \% \text{Detractors}$$

---

## 4. Telemetry Events & Analytics Taxonomy

When a believer interacts with the rating sheet, the following events are logged via `AppLogger`:

### `feedback_submitted`
- `rating`: (int, 1–5)
- `emoji`: (string, "😊", "😐", "😞")
- `face`: (string, "happy", "neutral", "sad")
- `nps`: (int, 1–10)
- `has_comment`: (bool, whether text comment was provided)
- `chapter`: (string, e.g. "1CO.13")
- `translation`: (string, e.g. "BSB")
- `platform`: (string, "android", "ios", "web")
- `app_version`: (string, "0.2.4")

### `better_feedback_submitted`
- `message_len`: (int, character count of feedback message)
- `has_screenshot`: (bool, whether screenshot was annotated)
- `screenshot_size_bytes`: (int, PNG byte length)
- `has_email`: (bool, whether user supplied follow-up email)
- `rating`: (int, 1–5)
- `face`: (string, "happy", "neutral", "sad")

### `feedback_delivery_completed`
- `doorbell_success`: (bool)
- `has_doorbell_config`: (bool)
- `latency_ms`: (int, round-trip HTTP submission duration)
- `nps`: (int, calculated score)

---

## 5. Security & Privacy Guardrails
1. **Zero Secret Leakage**: No Doorbell API keys, Firebase service accounts, or user emails are committed to Git.
2. **Private Pre-Triage**: Negative feedback is kept strictly private between the believer and Neil to ensure gentle, loving restoration and rapid debugging.
3. **Sanitized Telemetry**: Hardware IDs, IP addresses, and personal credentials are never passed in analytics event payloads.
