# Selah Project Rules & Guidelines

> [!IMPORTANT]
> These rules must be strictly adhered to by all developers and AI pair programmers working on this repository.

---

## 1. Zero Secrets & Key Safety Policy
- **NEVER commit API keys, tokens, or credentials to any public or private repository commit.**
- All API keys, tokens, and endpoints must be injected at build or runtime using `--dart-define`:
  ```bash
  --dart-define=API_BIBLE_KEY="YOUR_KEY"
  --dart-define=APTABASE_KEY="YOUR_KEY"
  --dart-define=USERORIENT_KEY="YOUR_KEY"
  --dart-define=DOORBELL_APP_ID="YOUR_APP_ID"
  --dart-define=DOORBELL_API_KEY="YOUR_API_KEY"
  ```
- In Dart source code, fallback values must always default to `'REDACTED'` or empty string `''`.
- Never check in `.env`, keystore files (`*.jks`, `*.keystore`), `key.properties`, `google-services.json`, or `GoogleService-Info.plist`.

---

## 2. Remote Push Gate (Review Before Push)
- **DO NOT push (`git push`) to any remote repository without explicit user review and permission.**
- Always review local commits, branch status, and staged diffs with the user first.

---

## 3. Architectural Integrity (CodeWithAndrea Feature-First Pattern)
- Code must reside in modular layers under `lib/src/`:
  - `lib/src/core/`: Cross-cutting concerns (analytics, constants, logging, theme, remote config, services).
  - `lib/src/features/<feature_name>/`: Grouped by domain (`domain/`, `data/`, `application/`, `presentation/`).
- Entrypoint `lib/main.dart` must remain concise, only initializing essential services and launching `ProviderScope`.

---

## 4. Vendor Independence & BaaS Abstraction
- BaaS capabilities (Auth, User Data, Remote Config) must be defined as abstract interfaces (e.g. `AuthRepository`, `ScriptureUserDataRepository`).
- Swapping between Firebase, Supabase, or Appwrite must require zero changes to the presentation layer.

---

## 5. Non-Blocking Analytics
- All analytics tracking must be fire-and-forget using `unawaited(...)` from `dart:async` so logging never delays the UI or audio playback threads.
