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

5. **PR Merge Governance**:
   - Merge branches into `main` exclusively through Pull Requests audited and triaged using the [.agents/skills/pr-coderabbit-triage-and-merge](../../skills/pr-coderabbit-triage-and-merge/README.md) skill, ensuring all critical blockers are fixed and non-critical items are deferred to tracked issues.

## Command Execution Permissions & Autonomous CLI Allowlist

### 1. Always Permitted Autonomous Commands
- `gh pr create`, `gh pr view`, `gh pr merge` (when all quality and triage gates pass).
- `gh issue create`, `gh issue list`, `gh issue view`.
- `git commit` (on dedicated ticket/feature branches with conventional commit syntax).
- `git push origin <ticket-branch>` (pushing to feature/ticket branches is fully authorized).
- `git status`, `git diff`, `git branch`, `git checkout`, `git add`.
- Python review triage and auto-defer scripts:
  - `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py`
  - `python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/defer_comments_to_issues.py`
- Test & verification commands: `flutter test`, `flutter analyze`.

### 2. Strictly Prohibited Operations
- `git push origin main` or any direct commit, push, or destructive force operation targeting `main`.
