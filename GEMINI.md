# Workspace Rules: Selah Scripture Audio Meditation

## Rule: Zero Plaintext API Keys & Secrets in Repository
Under NO circumstances may any API keys, access tokens, secret credentials, private keys, or passwords be written to files tracked by git, nor hardcoded as default fallback values in configuration files (such as `codemagic.yaml`, workflow files, `.env` files, or Dart sources).

### Strict Requirements
1. **No Plaintext Fallbacks**: In YAML or workflow files, NEVER use syntax like `${VAR:-plaintext_secret}` that embeds a fallback secret.
2. **Environment & Secrets**: Use only environment variables supplied at build time or via secure CI/CD groups (`groups: [selah_secrets]`).
3. **Dart Code Constants**: Always load sensitive keys via `String.fromEnvironment('KEY_NAME', defaultValue: 'REDACTED')`. Never embed actual tokens in source code or unit test mocks.
4. **Ignored Files**: Ensure files containing credentials (e.g., `google-services.json`, `GoogleService-Info.plist`, `.env*`, `*.keystore`, `*.jks`) are strictly included in `.gitignore`.
5. **Pre-Commit Verification**: Before executing `git commit`, inspect `git diff --staged` to verify no secret or credential was introduced.

## Rule: Mandatory Ongoing Session Status Tracking File
Every single session MUST have an active markdown status file named `<date>_selah_session.md` (e.g. `10oct_2026_selah_session.md`) located in the workspace root, maintained and proactively updated throughout every milestone of the session.

### Mandatory File Structure
1. **TL;DR**: Ultra-concise high-level state of the app and current focus.
2. **Executive Summary**: High-level overview of accomplishments, current blockers, and architecture state.
3. **Mini-Milestones Table**: Comprehensive table including:
   - Milestone ID & Title
   - Scope / Description
   - Start Time (`YYYY-MM-DD HH:MM:SS`)
   - End Time (`YYYY-MM-DD HH:MM:SS` or `IN-PROGRESS`)
   - Status (`COMPLETE`, `IN-PROGRESS`, `PENDING`)
   - Proof / Verification artifact
4. **Where We Are Right Now & Next 3 Priorities**: Clear explanation of current progress and the next 3 immediate tactical wins.
5. **FAQ**: Common questions, architectural decisions, and design rationale.
6. **Troubleshooting Guide**: Known error signatures, root causes, diagnostic checks, and mitigation steps.
7. **Appendix**: Relevant device IDs, URLs, commit hashes, telemetry logs, and CLI verification snippets.
