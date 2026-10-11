---
name: isolated-spike-and-pr
description: >-
  Executes small, self-contained, ticket-driven "side spikes", tech debt refactors,
  or CI/CD brainstorms in an isolated git worktree or dedicated branch. Troubleshoots
  and iterates with automated tests and visual proofs, and opens a clean, well-commented
  PR designed for an easy 30-second review.
---

# Isolated Spike & 30-Second Review PR Workflow

Use this skill whenever tasked with exploring, prototyping, or executing a self-contained side task, dependency evaluation (e.g. `pub.dev/retrofit`), CI/CD experiment, or technical debt refactoring without blocking or polluting ongoing mainline feature work.

---

## Philosophy & Core Rules
1. **Always Ticket-Driven**: Every sidecar spike MUST trace back to an open GitHub issue ticket (e.g. `#20`).
2. **Zero Pollution of Mainline Work**: Spikes are developed either in a dedicated `git worktree` or on a clean feature branch checked out from `main`. Never mix spike code with active, uncommitted feature branch work.
3. **The "30-Second Review" Standard**:
   - Scope is strictly disciplined (typically < 300 LOC diff, focused on 1 concept).
   - Code is self-explanatory with instructional doc comments ("minimal WTFs per minute").
   - Verification is undeniable: tests pass 100%, and visual/runtime proof artifacts are embedded directly in the PR description.
4. **Mandatory PR Readiness Grade**: Every spike PR must achieve a **B+** or **A-** readiness grade using the project's 5-category rubric.

---

## Workflow Steps

### Step 1: Ticket & Scope Triage
1. Check for an existing GitHub issue:
   ```bash
   gh issue list --search "<keyword>"
   ```
2. If no ticket exists, create one with clear acceptance criteria and appropriate labels (`infrastructure`, `devops`, `enhancement`):
   ```bash
   gh issue create --title "<type>: <concise title>" --body "<summary & acceptance criteria>" --label "<labels>"
   ```

---

### Step 2: Establish Isolated Workspace (Git Worktree or Branch)
To keep the primary working directory clean:

**Option A: Git Worktree (Recommended for long-running or dependency-heavy spikes)**
```bash
# From workspace root, create an isolated worktree off main
git worktree add ../selah-spike-<slug> -b <type>/#<ticket>-<slug> main
cd ../selah-spike-<slug>
flutter pub get
```

**Option B: Dedicated Ticket Branch (For quick, lightweight edits)**
```bash
git checkout -b <type>/#<ticket>-<slug> main
```

---

### Step 3: Implement, Troubleshoot & Iterate
1. Implement the minimal viable prototype or refactoring cleanly.
2. Maintain instructional clarity:
   - Add concise doc comments (`///`) explaining *why* an architectural choice was made.
   - Avoid cryptic abbreviations or convoluted one-liners.
3. Rapid Troubleshooting Loop:
   ```bash
   flutter analyze
   flutter test
   ```
4. Address any compilation, dependency, or static analysis issues iteratively until `flutter analyze` reports `0 issues`.

---

### Step 4: Generate Verification Proof
Every spike PR must provide concrete verification proof:

1. **Unit / Mock Test Proof**:
   - Write at least 1 unit test verifying the new client, helper, or refactored component (e.g. using `mocktail` or `package:test`).
   - Run the test suite:
     ```bash
     flutter test test/path/to/test.dart
     ```
2. **Visual Proof (If UI is touched)**:
   - Capture a screenshot via Marionette MCP or ADB:
     ```bash
     adb -s <device-id> exec-out screencap -p > docs/artifacts/screenshots/<name>.png
     ```
3. **CLI / Telemetry Proof**:
   - Copy key command outputs or log lines demonstrating the successful execution into the PR draft.

---

### Step 5: Package Conventional Commit & Push
1. Inspect the diff to ensure zero scope creep:
   ```bash
   git diff
   git status
   ```
2. Stage and commit following Conventional Commits scoped to the ticket:
   ```bash
   git add -A
   git commit -m "<type>(#<ticket>): <imperative summary>"
   ```
3. Push to the ticket branch on origin:
   ```bash
   git push origin <type>/#<ticket>-<slug>
   ```

---

### Step 6: Create the "30-Second Review" PR
Open the Pull Request using `gh pr create` with this exact template:

```bash
gh pr create --title "<type>(#<ticket>): <summary>" --body "$(cat << 'EOF'
## ⚡ Summary (30-Second Review)
- **Ticket**: #<ticket>
- **Objective**: <1-2 sentences explaining what was evaluated or refactored>
- **Scope Discipline**: <X files changed, +Y / -Z LOC; strictly isolated to ticket>

---

## 🔍 Key Decisions & Implementation Highlights
- **Decision 1**: <Why this pattern/package was chosen>
- **Decision 2**: <How backwards-compatibility or safety was preserved>

---

## ✅ Verification & Proof
- [x] Static Analysis: `flutter analyze` reports 0 issues.
- [x] Automated Tests: `flutter test` passes 100% (X/X tests green).
- [x] Visual / Runtime Proof: Attached screenshot or log snippet below.

### Visual / Runtime Artifact
![Artifact](<relative-or-absolute-image-path>)

---

## 🏆 PR Readiness Scorecard
- **Overall Grade:** A- (Ready for Quick Merge)
- **Merge Status:** Approved

| Category | Grade | Notes / Justification |
| :--- | :--- | :--- |
| **UX & Functional Polish** | A- | Clean behavior, zero regressions |
| **Maintainability & Architecture** | A | Strongly-typed, clean separation of concerns |
| **Ease of Review & Scope Discipline** | A | Atomic commits, minimal diff, 30-second review format |
| **Instructional Clarity & Minimal WTFs** | A | Self-documenting code with clear architectural rationale |
| **Verification & Proof** | A | Automated tests pass green; runtime proof verified |
EOF
)"
```

---

### Step 7: Cleanup (If Worktree Used)
After PR creation:
```bash
cd /Users/neil/AndroidStudioProjects/selah_prototype_audio_13sep2026
git worktree remove ../selah-spike-<slug>
```
