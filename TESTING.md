# Testing Selah

Unit and widget tests run without an ESV key, an API.Bible key, or a device. End-to-end flows need a booted emulator or a phone.

## Unit and widget tests

```bash
flutter analyze
flutter test
```

`scripts/run_flutter_checks.sh` does both, writes logs to `test_artifacts/flutter/`, and prints a coverage table. Line coverage ignores `*.g.dart`, `*.freezed.dart`, and `l10n`. The GitHub job fails under `COVERAGE_MIN` in `.github/workflows/flutter_ci.yml` (80% as of this branch; the last local run was 81.0%, 3,468 of 4,284 lines).

Shared fakes live in `test/support/fakes/`. Passage strings shared by tests live in `test/support/fixtures/passage_fixtures.dart`.

## Gherkin widget tests

Feature files under `test/features/journeys/` describe what a listener sees. The matching `*_test.dart` files run under `flutter test` with `bdd_widget_test`'s step style. They do not need a device.

```bash
flutter test test/features/journeys
```

Regenerating steps with `build_runner` waits on that dependency, which is landing separately.

## Maestro

Smoke flows are in `.maestro/smoke/`. They launch the installed app and do not embed secrets.

```bash
scripts/run_maestro_smoke.sh
```

Screenshots, view hierarchies, and the JUnit report go to `test_artifacts/maestro/<timestamp>/`. That folder is gitignored.

Other flows in `.maestro/` are the older device checks (feedback, chapter search, translations). Run one with `maestro test .maestro/smoke_test.yaml`.

## Patrol

Patrol tests drive the app on a device, including native UI. The CLI is `patrol_cli`.

```bash
dart pub global activate patrol_cli
patrol test -t integration_test/patrol_test.dart
```

`integration_test/app_test.dart` is the older Flutter integration test and can be run with `flutter test integration_test/app_test.dart -d <device>`.

## What each layer covers

| Journey | Unit | Gherkin widget | Patrol | Maestro |
| --- | --- | --- | --- | --- |
| Player opens on 1 Cor 13 and does not speak | yes | yes | header and passage only | smoke asserts the header and opening line |
| No ESV key: lookup is refused, speech does not start | yes | yes | | |
| Bundled audio stays offline until play | yes | | | |
| Missing audio prepares TTS and does not autoplay | yes | | | |
| WEB Old Testament has no human narrator | yes | | translation switch | |
| Unknown reference is rejected and the passage stays | yes | yes | | |
| Settings lists BSB and WEB without a key | | yes | | |
| Peace topic shows Philippians 4 and John 14 | | yes | | |
| Peaceful timing rating thanks the listener | | yes | | |
| Timing problem opens calibration choices | | yes | | |
| Missing timestamps can be requested | | yes | | |
| Psalm 23 search uses bundled audio and does not speak | | yes | | |
| Book browser selects Psalms 23 | | yes | | |
| Play control loads the bundled narrator without TTS | yes | yes | | |
| Sleep timer can be set to 15 minutes without speech | | yes | | |
| Tested-passage list can request an unaligned passage | | yes | | |
| Settings: 7 repetitions, 10s gap, karaoke off, prayer dialog | | yes | | |
| Roadmap idea and direct feedback need no account | yes | yes | | |
| Feedback issue is not sent when the token is missing | yes | | prayer dialog | older feedback flow |

Maestro still does not walk the offline, bad-reference, or no-autoplay journeys on a device. Those flows are listed in https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/261.
