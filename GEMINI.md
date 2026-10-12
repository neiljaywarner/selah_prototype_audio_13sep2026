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

## Rule: Zero Direct Pushes to Main, Ticket-Driven Branches & Conventional Commits
Under NO circumstances may any changes be pushed directly to the `main` branch. All development must be strictly ticket-driven and follow standard conventional commit naming.

### Strict Requirements
1. **Protected `main` Branch**: Never execute `git push origin main`. The `main` branch is strictly protected and updated exclusively through reviewed and triaged Pull Requests.
2. **Issue-First / Ticket-Driven Workflow**:
   - Every task, bug fix, feature, or refactor MUST be tracked by a GitHub issue ticket (e.g., `#6`, `#14`).
   - If a ticket does not exist for the work, create one first using `gh issue create` before creating a branch or writing code.
3. **Ticket-Named Branches**:
   - Create and work on dedicated feature branches that reference the ticket ID:
     - `feat/#<ticket-id>-<slug>` (e.g., `feat/#6-walking-mode`)
     - `fix/#<ticket-id>-<slug>` (e.g., `fix/#14-shuffle-repetition`)
     - `docs/#<ticket-id>-<slug>` (e.g., `docs/#10-licensing-notes`)
4. **Conventional Commits with Ticket Scopes**:
   - Every single git commit MUST follow the Conventional Commits specification and include the ticket number in the scope:
     - `feat(#<ticket>): <imperative summary>`
     - `fix(#<ticket>): <imperative summary>`
     - `docs(#<ticket>): <imperative summary>`
     - `test(#<ticket>): <imperative summary>`
     - `refactor(#<ticket>): <imperative summary>`
     - `chore(#<ticket>): <imperative summary>`
   - Examples:
     - `feat(#6): add background audio service and lockscreen controls`
     - `fix(#14): preserve iteration count across shuffle translation cycles`
5. **PR Merge Governance**:
   - Merge branches into `main` exclusively through Pull Requests audited and triaged using the [.agents/skills/pr-coderabbit-triage-and-merge](.agents/skills/pr-coderabbit-triage-and-merge/README.md) skill, ensuring all critical blockers are fixed and non-critical items are deferred to tracked issues.

### Command Execution Permissions & MCP-First Protocol
1. **MCP Server Precedence (MANDATORY)**:
   - Always prefer and use MCP tools (`github` MCP via `call_mcp_tool`, `marionette` MCP, `patrol` MCP) over local CLI commands.
   - For all GitHub operations (issue creation, PR creation, PR merging, comments, issue inspection), execute via the **`github` MCP server**, NEVER CLI `gh`.
2. **Permitted Autonomous Commands**:
   - `git commit` (on dedicated ticket/feature branches with conventional commit syntax).
   - `git push origin <ticket-branch>` (pushing to feature/ticket branches is fully authorized).
   - `git status`, `git diff`, `git branch`, `git checkout`, `git add`.
   - Python review triage and auto-defer scripts:
     - `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py`
     - `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/defer_comments_to_issues.py`
   - Test & verification commands: `flutter test`, `flutter analyze`.
3. **Strictly Prohibited Operations**:
   - `git push origin main` or any direct commit, push, or destructive force operation targeting `main`.

