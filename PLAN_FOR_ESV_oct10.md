# Plan for ESV (English Standard Version) Integration

> **Target:** Step-by-step implementation guide for an assistant or engineer to integrate Crossway's ESV API (API v3) into *Selah Scripture Audio Meditation*.  
> **Source Guidelines:** [https://api.esv.org/#copyright](https://api.esv.org/#copyright) & [https://api.esv.org/#api-v3](https://api.esv.org/#api-v3).  
> **Date:** October 10, 2026.

---

## 1. Compliance & Licensing Rules (Strict Enforcement)

Crossway enforces specific constraints for their free API v3 tier:

1. **Noncommercial Use Only:** The application must remain strictly noncommercial. No paywalls, paid subscriptions, or paid unlocks for ESV text.
2. **Attribution & Copyright Notice:** The following notice must be visibly displayed whenever ESV text is shown or spoken:
   ```
   Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard Version®), 
   copyright © 2001 by Crossway, a publishing ministry of Good News Publishers. 
   Used by permission. All rights reserved. The ESV and English Standard Version are registered trademarks of Crossway.
   ```
3. **Query Verse Limits:**
   - Maximum **500 verses per query** (or half a book of the Bible, whichever is less).
   - Single-chapter books (e.g. Obadiah, Philemon, 2 John, 3 John, Jude) may be requested in full.
4. **Rate Limits:**
   - **5,000 queries per day**.
   - No more than **1,000 requests per hour**.
   - No more than **60 requests per minute**.
   - Must handle HTTP `429 Too Many Requests` gracefully with exponential backoff and user notification.
5. **Local Storage / Caching Limits:**
   - **Do NOT locally store or database-cache more than 500 consecutive verses or one-half of any book.**
   - Only ephemeral memory caching for the active meditation session is permitted.
6. **Display Limit:**
   - Do not display more than 500 consecutive verses or one-half of a book on a single screen/page.

---

## 2. API v3 Authentication & Endpoints

- **Base URL:** `https://api.esv.org/v3`
- **Authentication Header:** `Authorization: Token <ESV_API_KEY>` (injected via `--dart-define=ESV_API_KEY=...`).
- **Primary Endpoint:**
  ```http
  GET /v3/passage/text/?q={passage}&include-headings=false&include-footnotes=false&include-verse-numbers=false&include-short-copyright=true
  ```
- **Audio Note:** Crossway's API v3 provides an audio endpoint:
  ```http
  GET /v3/passage/audio/?q={passage}
  ```
  *(Returns an HTTP 302 redirect directly to a high-quality MP3 audio stream of David Cochran Heath's reading).*

---

## 3. Step-by-Step Implementation Roadmap

### Step 3.1: Environment Variable & Constants
In `lib/src/core/constants/api_constants.dart`:
```dart
const String kEsvApiKey = String.fromEnvironment('ESV_API_KEY', defaultValue: 'REDACTED');
const String kEsvBaseUrl = 'https://api.esv.org/v3';
```

### Step 3.2: Register in `BibleTranslation` Enum
In `lib/src/features/meditation/domain/bible_translation.dart`, add:
```dart
esv(
  code: 'ESV',
  shortLabel: 'ESV',
  fullName: 'English Standard Version',
  audioBibleId: 'esv_crossway_audio',
  textBibleId: 'esv_crossway_text',
  hasOtNarrator: true,
  hasNtNarrator: true,
  isLicensed: true,
  copyright: 'Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard Version®), copyright © 2001 by Crossway. Used by permission. All rights reserved.',
),
```

### Step 3.3: Implement Crossway Dio Client & Service
Create `lib/src/core/services/esv_service.dart`:
- Set `BaseOptions(baseUrl: kEsvBaseUrl, headers: {'Authorization': 'Token $kEsvApiKey'})`.
- Implement `fetchChapterText(String passageQuery)`.
- Implement `getAudioStreamUrl(String passageQuery)` (returns redirect URL or handles 302 for audio stream).

### Step 3.4: Integrate in `ChapterPlayerNotifier`
In `ChapterPlayerNotifier.routeAndPlayChapter`:
- If `state.translation == BibleTranslation.esv`:
  - Route through `EsvService` to fetch passage text and streaming URL.
  - If `kEsvApiKey == 'REDACTED'`, switch to TTS fallback with an informative banner.

### Step 3.5: Rate Limit Throttler & Safe Caching
Implement an in-memory sliding window rate limiter:
- Reject requests locally if > 50 calls in 60 seconds to avoid IP block.
- Enforce the 500-verse cap per query.

### Step 3.6: Verify with Automated Tests
1. Unit tests in `test/unit/esv_service_test.dart` (mocking 200 OK, 429 rate limit, 500-verse clamping).
2. Widget tests verifying ESV chip appears in `SettingsBottomSheet` and `ChapterPlayerScreen`.
3. Verifying copyright string is visible when ESV is active.
