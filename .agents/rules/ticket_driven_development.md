# Rule: Zero Direct Pushes to Main, Ticket-Driven Branches & Conventional Commits

Under NO circumstances may any changes be pushed directly to the `main` branch. All development must be strictly ticket-driven and follow standard conventional commit naming.

## Strict Requirements

1. **Protected `main` Branch**:
   - Never run `git push origin main`.
   - `main` is strictly updated via approved, triaged Pull Requests.

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

5. **PR Merge Governance & Readiness Grading Rubric**:
   - Merge branches into `main` exclusively through Pull Requests audited and triaged using the [.agents/skills/pr-coderabbit-triage-and-merge](../../skills/pr-coderabbit-triage-and-merge/README.md) skill, ensuring all critical blockers are fixed and non-critical items are deferred to tracked issues.
   - **Mandatory PR Readiness Grade**: Even on a prototype or side project, we maintain professional engineering discipline and educational clarity. Every PR description and audit summary MUST include an explicit overall grade (e.g., `A`, `A-`, `B+`) evaluated across 5 core categories:
     1. **UX & Functional Polish**: Delightful end-user experience, zero regressions, authentic human narrator audio (no accidental robotic TTS fallbacks), sub-second WhisperX timestamp accuracy, and intuitive visual feedback.
     2. **Maintainability & Architecture**: Clean separation of concerns, robust state management, type safety, zero `flutter analyze` warnings, and extensible modular structure.
     3. **Ease of Review & Scope Discipline**: Strictly scoped to the ticket (no feature creep or drive-by refactors), atomic conventional commits, readable diff, and clear PR narrative.
     4. **Instructional Clarity, Mentoring & Minimal WTFs**: Code and commits must be disciplined "enough" for peer review, instructions, and mentoring. Complex logic is documented, naming is intuitive, architectural choices have ADRs, and changes produce minimal cognitive friction ("minimal WTFs per minute").
     5. **Verification & Proof**: BDD Gherkin specs, passing unit/widget/integration test suite, and concrete visual verification artifacts (Marionette/ADB screenshots, recordings, or before/after comparison tables).
   - **Grade Bar & Merge Threshold**:
     - **A / A- (Ready to Merge)**: Solidly meets or exceeds standards across all categories.
     - **B+ / Urgent Pass (Conditionally Merged)**: Meets functional core and passing tests, but minor polish or non-critical debt remains. **Mandatory follow-up protocol**: Allowed to merge ONLY if an urgent blocker or release need exists, AND all residual items or polish gaps are immediately filed as tracked GitHub issues (`gh issue create`) before or upon merge.
     - **B or lower (Merge Blocked)**: Does NOT meet the quality bar (e.g., scope runaway, messy hacks, high WTFs, missing test proof, or unresolved lints). Must be polished and fixed prior to merging.

## Command Execution Permissions & Autonomous CLI Allowlist

### 1. Generic Autonomous Pre-Approved Operations
The agent is fully authorized to execute all non-destructive development, testing, automation, and verification commands autonomously without prompting for parameter confirmation:
- **Flutter & Dart**: `flutter run` (on all attached devices/simulators/Chrome), `flutter build` (apk, web), `flutter test`, `flutter analyze`, `dart format`, `dart analyze`, `flutter pub get`.
- **Device & Automation (ADB / Marionette)**: `adb devices`, `adb install`, `adb shell`, `adb exec-out screencap`, `adb screenrecord`, `adb pull`, and Marionette MCP automation tools (`connect`, `tap`, `enter_text`, `take_screenshots`, `hot_restart`, etc.).
- **GitHub CLI**: `gh issue create`, `gh issue list`, `gh issue view`, `gh issue close`, `gh pr create`, `gh pr view`, `gh pr edit`, `gh pr comment`, `gh pr merge` (when all triage gates and quality bar pass).
- **Git Operations (Ticket-Driven Branches)**: `git status`, `git diff`, `git branch`, `git checkout`, `git add`, `git commit` (with conventional commit syntax scoped to ticket), `git push origin <ticket-branch>`, `git pull origin main`.
- **Analysis & Scripts**: `python3`, `curl`, `ripgrep`, `grep`, `find`, filesystem file reads and writes inside the workspace and artifact directories.
- **Background Processes**: Starting, monitoring, hot restarting, and cleanly terminating background runner processes (e.g., flutter daemon or test servers). Always close older browser or runner instances before launching new ones to avoid duplicate audio playback.

### 2. Strictly Prohibited Destructive Operations
- `git push origin main`, direct commits to `main`, or any destructive force operation targeting `main`.
- Destructive filesystem deletions outside transient artifacts or scratch directories (e.g. `rm -rf /` or deleting active source directories without ticket approval).
- Committing or logging plaintext secrets or API keys.
