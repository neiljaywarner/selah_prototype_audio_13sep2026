# Selah User Feedback & Pre-Triage Architecture

## 🎯 Overview & Purpose
Selah's feedback system measures how users experience the app, triages spiritual reflections and bug reports, and ensures sensitive prayer requests or user frustrations remain strictly confidential.

---

## 🎭 3-Face Feedback Funnel

```
               [ How do you like Selah? ]
               /           |            \
              /            |             \
        😊 Happy      😐 Neutral       😞 Sad
       (Promoter)      (Passive)     (Detractor)
           │               │              │
           ▼               ▼              ▼
     Rating 4–5 Stars  Private Funnel  Private Funnel
     Encourage Praise    "What could   "What went wrong
     & Public Sharing?   we improve?"   or felt broken?"
           │               │              │
           └───────┬───────┴──────────────┘
                   │
                   ▼
     [ Multi-Channel Submission ]
     ├── 1. Firebase Cloud Firestore (selahwordapp/user_feedback)
     ├── 2. Doorbell.io NPS (0–10 Score & Properties)
     └── 3. Private GitHub Hub (`njwandroid/selahfeedback`) & Direct Email
```

### 1. 😊 Happy (`'happy'`)
- **Reaction Emoji:** `😊` (Loving it!)
- **Default NPS:** `9` or `10` (Promoter)
- **Funnel Goal:** Encourages user to select 4 or 5 stars and share what they love most.
- **Button:** *Submit 5-Star Rating & Praise*

### 2. 😐 Neutral (`'neutral'`)
- **Reaction Emoji:** `😐` (It is okay)
- **Default NPS:** `7` (Passive)
- **Funnel Goal:** Funnels directly to private constructive feedback: *"Help us make Selah more peaceful for you."*
- **Action:** Submits privately to Firestore and gives 1-tap direct email / GitHub triage copy to `neilwarner+selah@gmail.com`.

### 3. 😞 Sad (`'sad'`)
- **Reaction Emoji:** `😞` (Needs work)
- **Default NPS:** `1` – `4` (Detractor)
- **Funnel Goal:** Empathy and instant private triage: *"We're so sorry! Tell Neil what felt frustrating or broken."*
- **Action:** Submits privately with device and OS context, routing directly to Neil.

---

## 🔒 Why the Triage Area is Private (`njwandroid/selahfeedback`)
Feedback from real users includes:
1. **Confidential Prayer Reflections**: Believers meditating on passages like Romans 8 or Psalm 23 often share intimate personal reflections, anxieties, or prayer needs that must never be publicly exposed on open issue trackers.
2. **Duplicate & Incomplete Bug Reports**: Non-technical users often submit one-sentence bug reports or duplicate logs that require internal pre-triage before polluting public engineering backlogs.
3. **Pre-Triage Review**: Issues in the private `njwandroid/selahfeedback` repo are reviewed by Neil and triaged:
   - Bugs are sanitized and escalated into public GitHub issues on `neiljaywarner/selah_prototype_audio_13sep2026`.
   - Feature requests are moved into the community feature voting board.
   - Prayer reflections are honored privately.

---

## 📱 Telemetry & Context Attachment
Every feedback submission automatically captures non-identifying technical metadata via `device_info_plus` and `package_info_plus`:
- **Platform**: `android`, `ios`, or `web`
- **Device Model & Manufacturer**: (e.g. `Pixel 9a`, `iPhone 16 Pro`)
- **OS Version & SDK**: (e.g. `Android 17`, `API 37`, `iOS 18.2`)
- **App Version & Build Number**: (e.g. `v0.2.4+1`)
- **Active Passage & Translation**: (e.g. `Matthew 11:28–30 (BSB)`)
- **NPS Score**: Calculated 0–10 score based on sentiment face and star rating.

---

## 🛠️ Dispatch Channels

| Channel | Storage / Destination | Security & Privacy |
| :--- | :--- | :--- |
| **Firestore Table** | `projects/selahwordapp/databases/(default)/documents/user_feedback` | Server-authenticated, queryable via Firebase console or Admin MCP |
| **Doorbell.io** | Doorbell Application API | Commercial feedback inbox with email notifications |
| **Private Email** | `neilwarner+selah@gmail.com` | Direct inbox routing with pre-filled technical context |
| **Private GitHub** | `njwandroid/selahfeedback` | Restricted repository for internal triage |
