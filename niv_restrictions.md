# NIV Licensing & Usage Restrictions via API.Bible

> **Target Audience:** Engineering, Product, and Legal / Publishing review for *Selah Scripture Audio Meditation*.  
> **Status:** Active / Binding for all releases distributing New International Version (NIV) content.  
> **Version:** 2011 text edition / 2011 Listener’s Bible™ audio edition.  
> **Last Verified:** October 2026 against API.Bible (American Bible Society) live endpoints and Biblica, Inc. published guidelines.

---

## 1. Inventory of Registered NIV Assets in Selah

| Asset | API.Bible ID | Official Name / Version | Rights Holder | Coverage |
| :--- | :--- | :--- | :--- | :--- |
| **Audio Bible** | `5dd1a42b02d2dee6-01` | *Holy Bible, New International Version®, The Listener's Bible™* | ℗ 2011 Max McLean / Fellowship for the Performing Arts | OT + NT (66 books) |
| **Text Bible** | `78a9f6124f344018-01` | *New International Version 2011 (NIV11)* | © 1973, 1978, 1984, 2011 Biblica, Inc.® | OT + NT (66 books) |

---

## 2. Core Legal Distinctions: Public Domain vs. Licensed

Unlike **BSB** (Berean Standard Bible, dedicated to the public domain) and **WEB** (World English Bible, public domain text), the **NIV is proprietary intellectual property** owned by Biblica, Inc. and administered commercially by HarperCollins Christian Publishing (Zondervan in North America, Hodder & Stoughton in the UK).

Because your API.Bible account has been granted access to the NIV:
1. Access is conditioned upon strict adherence to the **API.Bible Terms of Use** and **Biblica's Digital Redistribution Policies**.
2. Revocation of the API key immediately terminates the right to display or play cached NIV content.
3. Every API response includes a cryptographic **FUMS token** (`meta.fumsToken`) for royalty and audit accounting.

---

## 3. Mandatory Attribution & Copyright Notices

Whenever NIV text or audio is loaded or rendered, the following notices must be visible to the user:

### 3.1 Audio Attribution (The Listener's Bible™)
```
The Listener’s Bible®: NIV® Edition
Audio Copyright ℗ 2011 by Max McLean. Used by permission. All rights reserved worldwide.
The Holy Bible, New International Version® NIV®
Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.® All rights reserved worldwide.
```

### 3.2 Text Attribution
```
The Holy Bible, New International Version® NIV®
Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.®
Used by Permission of Biblica, Inc.® All rights reserved worldwide.
```

### 3.3 Trademark Notice
The acronyms **"NIV"** and **"New International Version"** are registered trademarks of Biblica, Inc. The app:
- **Must** use the `®` symbol on first mention in UI or store descriptions.
- **Must not** use "NIV" as the leading word of the application title (e.g., "Selah — Scripture Audio Meditation", not "NIV Meditation App").
- **Must** display: `"‘NIV’ and ‘New International Version’ are trademarks registered in the United States Patent and Trademark Office by Biblica, Inc.®"`.

---

## 4. Fair Use Management System (FUMS) Requirements

### What is FUMS?
API.Bible embeds a `meta.fumsToken` in every JSON payload for commercial/copyrighted bibles. FUMS allows American Bible Society and publishers (Biblica) to:
- Count discrete chapter and verse impressions.
- Validate that views stay within licensed quotas.
- Accurately distribute publisher royalties.

### Selah's Implementation Strategy
1. **Token Capture:** Handled in `ChapterPlayerNotifier._recordFumsToken()` for both `text` and `audio` requests.
2. **Audit Logging:** Emits an event with `{ translation: 'NIV', kind: 'audio' | 'text', chapter_id: ... }` to PostHog and Aptabase.
3. **Web / PWA:** When running on Chrome/Web, the standard FUMS beacon or JS tracker (`https://fums.api.bible/f3`) can be pinged with the token, device id, and session id.
4. **Native App (iOS / Android):** Native apps report token consumption via standard HTTP beacon or unawaited ping to the FUMS endpoint.

---

## 5. Caching, Storage, and Offline Restrictions

| Content Type | Allowed Storage | Max Duration | Notes |
| :--- | :--- | :--- | :--- |
| **Presigned S3 Audio URLs** | In-memory only | Until URL expires (`expiresAt` timestamp, typically 15–60 min) | **Never** save presigned URLs to SQLite, disk, or remote databases. Generate fresh URLs per session. |
| **Downloaded Audio Files (MP3)** | Ephemeral cache only | Session duration / 24 hrs max | Offline downloads require a direct, separate digital distribution agreement with Biblica and Max McLean. Streaming via API.Bible URLs is the only licensed method. |
| **Full Chapter Text** | Ephemeral memory cache | Max 24 hours | Bulk caching of entire books or offline SQLite databases of the full NIV text is strictly prohibited under standard API.Bible terms. |

---

## 6. Text Integrity & Transformation Rules

1. **No Text Alteration:** The scripture text must not be edited, paraphrased, reorganized, or truncated in a manner that distorts its canonical meaning.
2. **Synchronized Karaoke Highlighting:** Word-by-word visual highlight synchronized with audio is permitted as a reading aid, provided the underlying text is verbatim.
3. **Automated Text-to-Speech (TTS):** 
   - When using the NIV, Selah streams Max McLean's official human narration (`5dd1a42b02d2dee6-01`).
   - Third-party robotic TTS generation of proprietary NIV text should be avoided or limited to fallback scenarios, as some publisher agreements treat synthetic audio generation as creating a derivative audio recording.

---

## 7. Quotation Limitations & Biblica Permission Rules

For general digital publishing (outside custom private enterprise agreements), Biblica's standard permission limits specify:
- No more than **500 verses** quoted in aggregate in a single work.
- Verses quoted must not amount to **25% or more** of the complete text of the work in which they are quoted.
- Verses quoted must not account for an entire complete book of the Bible.

> **Note on API.Bible Integration:** Because API.Bible streams chapters on demand via authenticated API requests under ABS's overarching publisher agreement, user-directed on-demand reading/listening is covered. However, pre-packaging, scraping, or bundling all 66 books into the app bundle violates these guidelines.

---

## 8. Repetition & Meditation Loop Compliance

Selah features repetition loops (1x, 3x, 7x, ∞) with silent reflection gaps.
- Playing the same chapter audio multiple times within a user's prayer session is acceptable as a continuous playback session.
- The app must **not** simulate multiple synthetic API calls to artificially inflate impression counts. Only request a new URL when the audio session actually requires fresh retrieval.

---

## 9. Action Checklist for Production Release

- [x] Translation registry `BibleTranslation.niv` configured with exact IDs.
- [x] Both OT (e.g. Psalm 23) and NT (e.g. John 1) verified working via live REST curl.
- [x] In-app copyright strings updated in `SettingsBottomSheet` and `chapter_player_screen.dart`.
- [x] `fums_token_received` event captured in `AppLogger`.
- [ ] Add dedicated "Bible Copyrights" modal/section in the app's About / Legal dialog before App Store submission.
- [ ] Verify store listing contains required Biblica trademark disclaimers.
