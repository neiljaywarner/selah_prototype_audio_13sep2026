# Lesser-LLM plan: prove ESV verse lookup with video

You are a cheaper model finishing verification. The ESV code is already on this branch. Do not redesign it. Do not commit a real API key. Do not print the key in a log, a markdown file, a screenshot filename, or a PR comment.

## Already done (do not redo)

- `lib/src/core/esv/esv_api_client.dart` expands `1 Cor 13:4-7` into four queries and calls `GET https://api.esv.org/v3/passage/text/` once per verse with `Authorization: Token <key>`.
- Verse numbers, headings, footnotes, passage references, and the API's own `(ESV)` suffix are turned off. The player then shows `(ESV)` plus the short Crossway copyright in the info banner. The spoken line ends with `(ESV)` only.
- If `ESV_API_KEY` is missing or the call fails, search falls through to the old path: narrator excerpt when timestamps exist, otherwise `bible-api.com`, otherwise the TTS fallback.
- Chapter chips and the chapter picker still use API.Bible. ESV text is not written to the offline disk cache.
- Unit test: `test/unit/esv_api_client_test.dart` (the 4–7 expansion and a fake HTTP client that counts four calls).
- Maestro flow stub: `.maestro/esv_verse_lookup_flow.yaml`.
- GitHub Actions preview build (`.github/workflows/pr_preview_channel.yml`) passes `secrets.API_BIBLE_KEY`, `secrets.APTABASE_KEY`, `secrets.POSTHOG_KEY`, and `secrets.ESV_API_KEY` only when each secret is non-empty.

## Secret rules

The Crossway key belongs in two private places only:

1. The maintainer's `~/.zshrc` as `export ESV_API_KEY=...` (mode `600`).
2. GitHub Actions secret **name** `ESV_API_KEY`, next to `API_BIBLE_KEY`, `APTABASE_KEY`, and `POSTHOG_KEY`.

A cloud agent token received HTTP 403 on `gh secret list` / `gh secret set`, so the secret value may still be missing in GitHub. Check with:

```bash
gh secret list
```

If that prints `ESV_API_KEY`, continue. If it returns 403 or the name is absent, stop the video steps and write this exact sentence into the PR body: "Repo admin must add Actions secret ESV_API_KEY (value is the Crossway approval mail from 2026-10-19; do not paste it here)." Do not fetch Gmail and do not paste the key into the plan, the workflow, or the commit.

Local runs:

```bash
flutter run -d chrome \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY \
  --dart-define=ESV_API_KEY=$ESV_API_KEY
```

`String.fromEnvironment` reads the define at compile time. A shell export alone does nothing until that flag is passed. An empty define is treated as unset. The source default is the sentinel `REDACTED`.

## Rate limits (do not "optimize" these away)

Crossway free tier: **5,000/day**, **1,000/hour**, **60/minute**, **max 500 verses per request**. Do not locally store more than 500 consecutive verses. The client splits a same-chapter range into one call per verse, and refuses to split a range longer than 60 verses. Do not add a disk cache. Do not loop a whole book in a test.

## Step 1 — unit test (required, no device)

```bash
flutter test test/unit/esv_api_client_test.dart
flutter analyze lib/src/core/esv lib/src/core/constants/api_constants.dart lib/src/features/meditation/application/chapter_player_notifier.dart lib/src/features/meditation/presentation/chapter_player_screen.dart
```

Pass criteria: the 4–7 test expects exactly `['1 Cor 13:4', '1 Cor 13:5', '1 Cor 13:6', '1 Cor 13:7']`, and the HTTP test expects four calls whose `Authorization` header is `Token test-key` (the fake key in the test, not a real one). Fix compile errors in those files only. Do not weaken the expects.

Then:

```bash
git diff --cached | grep -qE 'ESV_API_KEY=.+[A-Za-z0-9]{16}' && echo 'SECRET LEAK' || echo 'no key in staged diff'
```

If that prints `SECRET LEAK`, unstage the file and remove the value before any commit.

## Step 2 — Maestro video (required when a device or emulator exists)

1. `flutter devices`. If nothing mobile is connected, skip to Step 2b. Do not invent a screenshot.
2. Build and install with the define (debug is enough):

```bash
flutter run -d <device-id> \
  --dart-define=ESV_API_KEY=$ESV_API_KEY \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY
```

Stop that run once the app is installed (`q`), or build an APK and `adb install -r` it. The installed binary must contain the define or the flow will not show `(ESV)`.

3. Record:

```bash
mkdir -p docs/artifacts/screenshots docs/artifacts/videos test_artifacts
maestro record .maestro/esv_verse_lookup_flow.yaml
```

If `maestro record` is not a subcommand, run `maestro --help` and use whichever subcommand writes an mp4. Fallback while the flow runs:

```bash
adb shell screenrecord --time-limit 45 /sdcard/esv_verse_lookup.mp4 &
RECORD_PID=$!
maestro test .maestro/esv_verse_lookup_flow.yaml
kill $RECORD_PID 2>/dev/null || true
adb pull /sdcard/esv_verse_lookup.mp4 docs/artifacts/videos/esv_verse_lookup.mp4
```

4. Copy Maestro screenshots from `test_artifacts/` or `~/.maestro/tests/` into `docs/artifacts/screenshots/`. The frames must show the player text ending with `(ESV)` for `John 11:35` and for `1 Cor 13:4-7`.

5. Confirm the search field, not a chapter chip, was used. `1 Cor 13:4-7` typed into search is the ESV path. Tapping the curated chip is API.Bible narrator audio and does **not** satisfy this task.

## Step 2b — Chrome stand-in when no phone is attached

```bash
flutter run -d chrome --web-port 8088 \
  --dart-define=ESV_API_KEY=$ESV_API_KEY \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY
```

Drive it with the computer-use browser, or Maestro web if `maestro --help` shows a web target:

1. Click the search field that contains `John 1`.
2. Replace it with `John 11:35` and press Play. Wait until the banner or passage contains `(ESV)`.
3. Repeat with `1 Cor 13:4-7`.
4. Save a screen recording to `docs/artifacts/videos/esv_verse_lookup.web.mp4` and screenshots beside it.

If Chrome cannot reach `api.esv.org`, say so in the PR and keep the unit test as the proof. Do not substitute bible-api.com text and label it ESV.

## Step 3 — Patrol (only with a device)

Create `integration_test/esv_verse_lookup_patrol_test.dart` by copying the header imports from `integration_test/patrol_test.dart`. The test body:

1. `await $.pumpWidgetAndSettle(const ProviderScope(child: SelahApp()));`
2. Enter `John 11:35` into the search field (the field's initial text is `John 1`).
3. Tap `Play`.
4. `expect($(find.textContaining('(ESV)', findRichText: true)), findsWidgets);` after a pump that allows the network future to finish. Patrol on a device needs the same `--dart-define=ESV_API_KEY=$ESV_API_KEY` passed through `patrol test`.
5. Run: `patrol test -t integration_test/esv_verse_lookup_patrol_test.dart --dart-define=ESV_API_KEY=$ESV_API_KEY`
6. Copy Patrol's failure or success screenshots into `docs/artifacts/screenshots/`.

Do not add this file if `flutter devices` shows no mobile target. `flutter test` must stay green without a device. Patrol files live under `integration_test/`, not `test/`.

## Step 4 — Marionette (VM service smoke, not the scripture proof)

Marionette does not fetch ESV text. It only proves the debug VM is alive while that build is running.

```bash
flutter run -d <device-or-chrome> --dart-define=ESV_API_KEY=$ESV_API_KEY
```

Copy the `ws://127.0.0.1:<port>/<token>/ws` line from the log, then:

```bash
dart run scripts/marionette_smoke_suite.dart 'ws://127.0.0.1:<port>/<token>/ws' \
  | tee docs/artifacts/marionette_esv_smoke.txt
```

Pass criteria: the script prints `Marionette VM Service smoke suite completed successfully`. A missing VM URI is a skip, not a fake log. Do not commit the VM service token if the log line contains one; redact the token before committing the txt file.

## Step 5 — commit and PR

Commit only code, the Maestro flow, screenshots, and the video. Push the existing branch. Update the PR. The PR description must include:

- The `flutter run` command with `--dart-define=ESV_API_KEY=$ESV_API_KEY`.
- The four rate limits: 5,000/day, 1,000/hour, 60/minute, 500 verses/request.
- Where the secret lives (`secrets.ESV_API_KEY` plus local `~/.zshrc`), and that the value is not in git.
- Which of Maestro, Patrol, and Marionette actually ran, with links or paths to the video and screenshots. If a harness did not run, say why in one sentence.

## Do not

- Hardcode the Crossway key, or replace the `REDACTED` default with a real key.
- Switch chapter loading off API.Bible.
- Cache ESV text or audio to disk.
- Call the API in a loop inside `flutter test` (the unit test uses a fake adapter).
- Delete the bible-api.com fallback.
