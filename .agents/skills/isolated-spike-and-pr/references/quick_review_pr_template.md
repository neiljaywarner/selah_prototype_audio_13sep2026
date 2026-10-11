# 30-Second Review PR Template

Use this template when creating pull requests for side spikes, tech debt refactors, or dependency spikes.

```markdown
## ⚡ Summary (30-Second Review)
- **Ticket**: #<ticket>
- **Objective**: <1-2 sentences explaining what was evaluated or refactored>
- **Scope Discipline**: <X files changed, +Y / -Z LOC; strictly isolated to ticket>

---

## 🔍 Key Decisions & Implementation Highlights
- **Architecture**: <Pattern used, e.g. Retrofit REST client interface>
- **Safety / Zero Regression**: <How existing behavior was preserved>

---

## ✅ Verification & Proof
- [x] Static Analysis: `flutter analyze` reports 0 issues.
- [x] Automated Tests: `flutter test` passes 100% (X/X tests green).
- [x] Proof Artifact: Attached screenshot, before/after table, or CLI output.

---

## 🏆 PR Readiness Scorecard
- **Overall Grade:** A- (Ready for Quick Merge)
- **Merge Status:** Approved

| Category | Grade | Notes / Justification |
| :--- | :--- | :--- |
| **UX & Functional Polish** | A- | Clean behavior, zero regressions |
| **Maintainability & Architecture** | A | Strongly typed, modular, decoupled |
| **Ease of Review & Scope Discipline** | A | Strictly scoped to ticket, readable atomic diff |
| **Instructional Clarity & Minimal WTFs** | A | Clear comments, mentoring-ready documentation |
| **Verification & Proof** | A | Passing tests and runtime verification artifact |
```
