# Selah Share Session History (7–8 Nov 2026)

Sanitized review log of the biblebot chat that produced [PR #244](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/244) (`cursor/share-passage-link-e23e`). Secrets, API keys, tokens, local credential files, and internal machine paths are omitted. Email addresses below are only those already used as part of this work.

Related issues: [#240](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/240) (parent), [#245](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/245), [#246](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/246), [#247](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/247), [#248](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/248), [#249](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/249).

Times are America/Chicago.

---

## TL;DR

- Implemented share-a-passage ([#240](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/240)) on [PR #244](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/244). Recipients do not need an account. The v1 share payload is the reference, a `?ref=` URL, and short attribution — not the verse body.
- Covered the flow with Gherkin / `bdd_widget_test`, then Maestro and Patrol (first executed on Neil’s Mac).
- Recorded a Psalm 62:5-7 *send* demo (ESV attribution) and emailed it after Neil pressed Send.
- Receiving a web `?ref=` link is implemented. Opening that link in an already-installed Android app is not ([#245](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/245)).
- Follow-on tickets: include verse text in shares with licensing guardrails ([#246](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/246)), email-specific share behavior ([#247](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/247)), share analytics ([#248](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/248)).
- A receive recording of `?ref=Psalm+62:5-7` showed the BSB curated-excerpt collision (heading 62:5-7, words/audio from 62:1-2). Filed and fixed as [#249](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/249).
- Tried John 16:32-33 in ESV, BSB, and WEB. The range stayed put. Two more bugs were fixed: Helloao WEB id (`WEB` 404s; `eng_web` is correct), and switching translation dropped the shared excerpt.
- Local KVM Android testing was started on 8 Nov 2026: all **187** unit and widget tests passed. Patrol and Maestro on the emulators were still running when this log was written.
- The pull request was not merged.

---

## Standing constraints from this chat

- Do not commit secrets. Do not write API keys into the repo.
- Do not overwrite production [selahword.web.app](https://selahword.web.app) as part of this share work.
- Recipients should play signed-out.
- Prefer Gherkin and `bdd_widget_test` where a widget test can cover the scenario.
- ESV is the default when the ESV API key is compiled in and the experimental API.Bible narrator toggle is off.
- Share attribution follows the player’s current translation.
- Do not implement [#238](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/238) / [#239](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/239) (auth/sync) or song tickets [#241](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/241)–[#243](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/243) as part of this PR.
- Do not merge [#244](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/244) unless Neil asks.

---

## Chat timeline

### 7 Nov 2026 — implement #240

Neil asked to do [#240](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/240), then “bdd plz with gherkin”, then “bdd_widget_test where feasible plz”.

[PR #244](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/244) opened: share the playing passage or one from My Passages. The link carries the reference only (`?ref=1+Cor+13:4-7` or `?ref=Psalm+62:5-7`). Opening it lands on that range with play ready (no autoplay). A broken reference shows a friendly error. Gherkin lives in `test/features/share_a_passage.feature`.

### 7 Nov 2026 — Maestro and Patrol on the Mac

Neil: “plz test with maestro and patrol. use my mac if needed.”

Maestro web, Maestro Android (real share sheet), and Patrol were added and executed on the Mac. Suites passed. Android share-sheet Maestro initially showed BSB (`Public Domain · Narrator: Barry Hays`) because that debug APK was built without the ESV key compiled in.

### 7–8 Nov 2026 — Psalm 62:5-7 send video and email

Neil asked to record a Maestro video of sharing **Psalm 62:5-7** (not 1 Cor 13:4-7) and email it to his Gmail plus-tag (`neilwarner+selah@gmail.com`; “Warren” treated as a typo of Warner).

He then asked:

- It should still use ESV by default, right?
- How about the disambiguation dialog?
- Please file a GitHub issue for the JSON association files so an installed Android app opens the shared https link, with Firebase Hosting details.

Answers recorded in the chat:

- Yes, ESV by default when the key is compiled in and the experimental narrator is off. The video rebuild used that path and showed `ESV® © Crossway · Audio ℗ Crossway / David Cochran Heath`.
- The “disambiguation” UI is search suggestion chips (2+ characters, no colon). Incoming `?ref=Psalm+62:5-7` parses exactly and skips the chapter picker.
- [#245](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/245) filed under [#240](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/240): Digital Asset Links `assetlinks.json` at the host root, Firebase Hosting `**/.*` ignore (would skip `.well-known`), SPA rewrite notes, and why GitHub Pages project paths are a poor place to claim the domain.

The send demo (`share_psalm_62_5_7.mp4`, about 79 seconds) showed signed-out ESV, the full reference entered without Psalm/Psalms chips, playback, the Android share sheet with `Listen to Psalm 62:5-7 in Selah`, the `?ref=Psalm+62:5-7` link, and Crossway attribution — not the verse body. Neil pressed Send on the draft. Mail went out from `tal17@mail.grokbot.com` to `neilwarner+selah@gmail.com`. That message should not be sent again.

### 8 Nov 2026 — how much of receiving is done?

Neil asked how much of receiving a share is done, how we feel about the Material share icon on Android or browser, and for a video of receiving the share even if a disambiguation / “Open with” dialog appears because there is no association file yet. He also asked whether an emailed URL on selahword.web.app as a query parameter should work when this is done.

Answers:

- **Destination (web):** done. `?ref=` is read from the page URL, parsed exactly, and the signed-out player lands on that passage. Play is not automatic.
- **Android doorbell:** not done. No VIEW/BROWSABLE intent-filter yet, so there is no “Open with” chooser; the link goes to the browser. Verified App Links are the rest of [#245](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/245).
- **Material icon:** yes for Android and browser (`Icons.share`). Keep `ios_share` on iOS. The button is still `Icons.ios_share_rounded` on every platform; not swapped unless Neil asks.
- Intended hosted URL: `https://selahword.web.app/?ref=Psalm+62:5-7`. Web shares already use the current origin. Mobile/native shares still point at GitHub Pages until the public origin changes. Production does not have this PR yet.

The receive clip was recorded on a cloud web build after the Mac was offline (`receive_psalm_62_5_7.mp4`, about 39 seconds). It opened `/?ref=Psalm+62:5-7` signed out with “Press play to listen to Psalm 62:5-7.” After play on BSB (no ESV key in that run), the heading stayed 62:5-7 but the words and audio were the curated Psalm 62:1-2 meditation / unclipped chapter, with “Verse timing unaligned.”

### 8 Nov 2026 — share the verse text; email and analytics as separate issues

Neil (speech-to-text, interpreted in chat and confirmed by follow-up): include the verse text in the share, not only ref and URL — “Content is king especially the Word of God.” Recipients who get it by email should be able to read the words without clicking or turning a speaker on. Autofilling an email subject and treating email differently can be a separate issue. Please add good analytics for which share method is used most and which passages are shared most.

Tickets filed under [#240](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/240):

- [#246](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/246) — include verse text (ESV Crossway guardrails; BSB public-domain preview path; NIV withheld pending clear Biblica terms).
- [#247](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/247) — email shares / autofilled subject.
- [#248](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/248) — share analytics (`share_method`, passages, translation, experimental narrator flag).

Neil: “Nice job. Make bsb better if you can because bsb is still there under preview/experiment feature I think.” Those three tickets were updated for the BSB preview/experiment path.

This does **not** change what PR #244 already ships: the current payload is still reference + URL + short attribution. Verse text in the outbound share is follow-on [#246](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/246).

### 8 Nov 2026 — “Yes please keep goin” and #249

After the receive clip, Neil asked to keep going. [#249](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/249) was filed and fixed on the same PR.

Root cause (verified on the branch): `PassageExcerpt.forChapter('PSA', 62)` is the curated 62:1-2 meditation. Fetching chapter text ignored the shared custom excerpt, and clip timestamps for 5-7 were missing, so the bundled Psalm 62 chapter played from verse 1. After the fix, BSB play of a shared 62:5-7 keeps heading, words, and audio on that range. The on-screen BSB starts “Rest in God alone, O my soul…”. If a range cannot be clipped, Selah reads those verses aloud instead of substituting another excerpt. The same rule keeps `1 Cor 13:8-13` from picking up “Love is patient…”. ESV still requests `Psalm 62:5`, `62:6`, and `62:7`. Gherkin: `test/features/receive_shared_passage.feature`.

### 8 Nov 2026 — try John 16:32-33 in ESV, BSB, and WEB

Neil: try another passage such as Ephesians 1 or John 16:33; “How about the John 16:33 couple of verses?” in ESV, BSB, and WEB.

We used **John 16:32-33** (the couple of verses ending at 16:33). John 16 is not a curated or bundled chapter. Results:

- **BSB.** Heading stays `John 16:32-33`. Words begin “Look, an hour is coming and has already come when you will be scattered…” and include “But take courage; I have overcome the world!” No bundled John 16 file, so Selah reads those verses aloud. Timing bar: “Verse timing unaligned.” Attribution: `Public Domain · Narrator: Barry Hays`.
- **WEB.** Heading stays `John 16:32-33`. Words begin “Behold, the time is coming, yes, and has now come, that you will be scattered…” and include “cheer up! I have overcome the world.” Same read-aloud path and unaligned timing bar. Attribution: `Public Domain · Audio ℗ 2013 Hosanna`.
- **ESV.** Heading stays `John 16:32-33`. The player requests `John 16:32` and `John 16:33` one at a time, then the passage audio URL for the range. The cloud run did not have the ESV key set, so Crossway was not called live; fixture text was used to exercise the path. With a real key, that path plays the ESV narrator; if audio fails, the fetched verses are read aloud. Timing bar hidden. Attribution is the Crossway line.

Two bugs found and fixed on this branch:

1. WEB text was requested from Helloao as `WEB`, which 404s. Helloao’s id for the World English Bible is `eng_web`. This showed up on John 16 because that chapter is not bundled, so WEB text had to be fetched.
2. Switching translation dropped the shared excerpt, so 16:32-33 would have become the whole chapter.

Gherkin: `test/features/receive_john_16.feature`.

Neil asked why Helloao was used, expecting API.Bible for WEB. That question was still open when he asked to run the full local test suite instead.

### 8 Nov 2026 — full local tests and this log

Neil: “Anyway just test it 100 percent please unit and widget and patrol and maestro work your local kvm emulators for Android.”

Then: make atomic commits, and commit a safe sanitized history of the chat to the pull request so it can be reviewed later.

Local results at the time this file was written:

- Full `flutter test`: **187 passed**, 0 failed (unit + widget, including share and John 16 scenarios).
- Two KVM Android emulators were already running (`belong_call_1` on `emulator-5554`, `belong_call_2` on `emulator-5556`).
- Debug APK build for Maestro, plus Patrol and Maestro device runs, were in progress.

---

## Current commits on the share branch (do not rewrite)

These already landed as separate commits on `cursor/share-passage-link-e23e`:

1. `feat(share): send a passage reference without verse text`
2. `test(share): cover passage links with Maestro and Patrol`
3. `fix(share): keep a shared range off a different curated excerpt` ([#249](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/249))
4. `fix(share): keep John 16:32-33 when the translation changes`

This document should be added as its own follow-up commit, without rewriting the history above.

---

## Still open (not done in this PR unless Neil asks)

- Merge of [PR #244](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/pull/244)
- [#245](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/245) Android App Links / `assetlinks.json`
- [#246](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/246) verse text in the share payload
- [#247](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/247) email-specific share behavior
- [#248](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/248) share analytics
- Swap to Material share icon on Android/web
- Re-record the receive clip after the [#249](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/249) fix
- Why WEB text fetch used Helloao vs API.Bible (question raised; not fully answered yet)
- Live ESV verification of John 16:32-33 with a compiled-in key
