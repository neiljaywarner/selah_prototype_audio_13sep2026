---
name: add-translation
description: >-
  Guides and automates adding a new Bible translation to Selah. Conducts an interactive interview
  to select the provider (API.Bible, YouVersion Platform Services, Crossway ESV API, or Public Domain),
  configures copyright compliance, FUMS telemetry, narrator credits, offline boundaries, and updates
  the About dialog and Licensing Attribution sheet.
---

# Add Translation Skill: Provider Selection & Licensing Architecture

Use this skill whenever adding a new Bible translation or audio stream to Selah. It guides the engineering agent through an interactive evaluation of API options, legal terms, telemetry requirements, and code updates.

---

## Phase 1: The Interactive Provider Interview ("Grill the User")

Before writing code, question the user or verify technical specifications across these 5 pillars:

### 1. Which Provider / API Platform?
Ask which service will deliver the text and audio:
- **Option A: API.Bible (American Bible Society / DBL)**
  - *Authentication*: `api-key` header (loaded dynamically from Remote Config or `--dart-define=API_BIBLE_KEY`).
  - *IDs Required*: `textBibleId` (e.g. `78a9f6124f344018-01`), `audioBibleId` (e.g. `5dd1a42b02d2dee6-01`).
  - *Telemetry*: **Mandatory FUMS (Fair Use Message System)** reporting upon chapter fetch.
  - *Caching*: Proprietary audio streams (e.g. NIV) **MUST NEVER** be cached to disk.
- **Option B: YouVersion Platform Services (Bible.com API)**
  - *Authentication*: OAuth2 Bearer token / Developer Application Key.
  - *Coverage*: 2,000+ translations and global audio bibles.
  - *Restrictions*: Requires "Powered by YouVersion" badge, strict rate-limiting, and compliance with publisher pass-through terms.
- **Option C: Crossway ESV API**
  - *Authentication*: `Authorization: Token <ESV_API_KEY>`.
  - *Endpoints*: Text (`https://api.esv.org/v3/passage/text/`), Audio (`https://api.esv.org/v3/passage/audio/`).
  - *Mandatory Legal Notice*:
    > "Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard Version®), copyright © 2001 by Crossway, a publishing ministry of Good News Publishers. Used by permission. All rights reserved."
  - *Narrator*: David Cochran Heath (Crossway Audio).
- **Option D: Direct Public Domain / Open Access (BSB, WEB, KJV, ASV)**
  - *Authentication*: None. Fully offline-capable.
  - *Caching*: Unlimited offline disk persistence and local looping permitted.

### 2. Is the Translation Public Domain or Proprietary?
- **Public Domain (`isLicensed: false`)**:
  - Example: Berean Standard Bible (BSB), World English Bible (WEB).
  - Can be pre-bundled in assets and cached indefinitely.
- **Proprietary Licensed (`isLicensed: true`)**:
  - Example: NIV (Biblica, Inc.), ESV (Crossway), NLT (Tyndale House).
  - Must display publisher copyright notices, trade dress, and cannot be bundled as raw MP3 files without explicit commercial distribution license.
  - Must fall back gracefully to on-device TTS if offline.

### 3. Audio Narration & Testament Availability
- Old Testament narrator available? (`hasOtNarrator: bool`)
- New Testament narrator available? (`hasNtNarrator: bool`)
- Who is the narrator? (e.g., Barry Hays, Max McLean, David Cochran Heath, Kelly Dolan).

---

## Phase 2: Systematic Codebase Update Checklist

When adding a translation (e.g. `esv`, `nlt`), complete every step below in order:

### Step 1: Update Domain Enum
File: `lib/src/features/meditation/domain/bible_translation.dart`
1. Add new enum value:
   ```dart
   esv(
     code: 'ESV',
     shortLabel: 'ESV',
     fullName: 'English Standard Version',
     audioBibleId: '<audio-id>',
     textBibleId: '<text-id>',
     hasOtNarrator: true,
     hasNtNarrator: true,
     isLicensed: true,
     copyright: 'Scripture quotations are from the ESV® Bible, copyright © 2001 by Crossway. Used by permission.',
   ),
   ```
2. Update getters:
   - `shortAttribution`: `'ESV® © Crossway · Audio ℗ Crossway'`
   - `narratorCredit`: `'David Cochran Heath'`
   - `audioLicensingTerms`: Document streaming and royalty terms.

### Step 2: Configure Client Routing & Telemetry
File: `lib/src/features/meditation/application/chapter_player_notifier.dart`
1. Ensure Dio client injects correct provider authentication header.
2. If API.Bible, verify `_recordFumsToken(res.data)` is called.
3. If offline and `translation.isLicensed == true`, verify graceful switch to `_switchToTtsFallback`.

### Step 3: Register Offline Text Excerpts
File: `lib/src/core/cache/offline_scripture_cache.dart`
- Provide offline fallback text for Top 12 curated meditation passages (e.g. 1 Cor 13:4–7, Matt 11:28–30, Psalm 23).

### Step 4: Update UI Attributions & About Page
Files:
- `lib/src/features/meditation/presentation/about_selah_dialog.dart`:
  - Update copyright section to explicitly list the new translation and publisher.
- `lib/src/features/meditation/presentation/widgets/licensing_attribution_sheet.dart`:
  - Ensure the modal displays full text and audio rights with publisher badges.

---

## Phase 3: Quality & Verification Protocol

Before opening a PR:
1. **Analyze**: `flutter analyze` (0 issues).
2. **Unit & Widget Tests**:
   ```bash
   flutter test test/unit/bible_translation_test.dart
   flutter test test/widget/licensing_attribution_sheet_test.dart
   ```
3. **Zero Plaintext Secrets Check**:
   ```bash
   git diff --staged | grep -E "(AIza|ghp_|UlsO|OXwR)"
   ```
4. **Inspect UI**: Verify About Dialog and Licensing Sheet render cleanly across mobile and web viewports without `RenderFlex` overflows.
