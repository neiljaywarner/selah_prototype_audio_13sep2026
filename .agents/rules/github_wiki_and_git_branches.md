# Rule: GitHub Wiki Master Branch Exclusivity & Isolation

## Core Principle
Under standard development, the primary code repository operates on branch `main` (strictly protected, PR-governed) and dedicated ticket branches (`feat/#<ticket>`, `fix/#<ticket>`).

**`git push origin master` is strictly prohibited in the code repository.**

## The Single Exception: GitHub Wiki Git Repository
GitHub Wikis are separate Git repositories hosted at `<repo-url>.wiki.git` (e.g., `https://github.com/neiljaywarner/selah_prototype_audio_13sep2026.wiki.git`), where GitHub enforces `master` as the default and only branch.

### Strict Wiki Operational Requirements:
1. **Pushing to `master`**: `git push origin master` is **ONLY** allowed inside the isolated GitHub Wiki git repository.
2. **Directory Isolation**:
   - The cloned wiki repository must NEVER be placed in a directory tracked by the primary code repository.
   - Always clone the wiki into `.worktrees/selah_wiki` or paths explicitly excluded in `.git/info/exclude` / `.gitignore`.
3. **Zero Contamination**:
   - Never allow `.wiki.git` files or commit objects to be checked into the primary repository.
   - Verify `git status` in the primary workspace remains completely clean of wiki artifacts.
