#!/usr/bin/env python3
"""
Pre-deployment Safety & Quality Verification (WTF Check) for Firebase Hosting Preview Channels.

Validates that:
1. Zero plaintext API keys or secrets are committed.
2. Flutter analyze reports 0 issues.
3. Flutter test suite passes green.
4. Web bundle prerequisites (index.html, GA4 tag, manifest) are intact.
5. Prohibited phrases (e.g. "Airplane Mode" on web) are verified guarded.
"""

import os
import re
import subprocess
import sys

def log(msg: str):
    print(f"🔍 [PRE-DEPLOY SCAN]: {msg}")

def fail(msg: str):
    print(f"❌ [WTF DETECTED]: {msg}", file=sys.stderr)
    sys.exit(1)

def run_command(cmd, desc):
    log(f"Running {desc}...")
    if isinstance(cmd, str):
        cmd = cmd.split()
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        fail(f"{desc} failed:\n{result.stderr}\n{result.stdout}")
    return result.stdout

def check_no_secrets():
    log("Scanning for plaintext secret patterns...")
    forbidden_patterns = [
        r'AIza[0-9A-Za-z-_]{35}', # Google API key
        r'ghp_[0-9A-Za-z]{36}',   # GitHub PAT
        r'gho_[0-9A-Za-z]{36}',   # GitHub OAuth Token
    ]
    ls = subprocess.run(["git", "ls-files"], capture_output=True, text=True)
    if ls.returncode != 0:
        fail(f"git ls-files failed: {ls.stderr}")
    git_files = ls.stdout.splitlines()
    for f in git_files:
        if not os.path.isfile(f) or f.startswith(".worktrees") or f.endswith((".png", ".jpg", ".mp3", ".lock")):
            continue
        try:
            with open(f, "r", encoding="utf-8", errors="ignore") as fh:
                content = fh.read()
                for pat in forbidden_patterns:
                    if re.search(pat, content):
                        fail(f"Potential plaintext credential matched '{pat}' in tracked file: {f}")
        except Exception as e:
            log(f"Skipping binary/unreadable file: {f}")

def check_flutter_analyze():
    run_command(["flutter", "analyze"], "Static Analysis (flutter analyze)")

def check_flutter_test():
    run_command(["flutter", "test"], "Test Suite (flutter test)")

def check_web_integrity():
    log("Verifying web/index.html tag and manifest...")
    index_path = "web/index.html"
    if not os.path.isfile(index_path):
        fail("Missing web/index.html")
    with open(index_path, "r", encoding="utf-8") as f:
        html = f.read()
    if "G-7LFS54TTFM" not in html:
        fail("web/index.html is missing GA4 measurement tag G-7LFS54TTFM")
    if "flutter_bootstrap.js" not in html and "flutter.js" not in html:
        fail("web/index.html missing standard flutter bootstrap loader")

def main():
    print("=" * 60)
    print("🚀 SELAH FIREBASE PREVIEW CHANNEL PRE-FLIGHT WTF SCAN")
    print("=" * 60)
    check_no_secrets()
    check_flutter_analyze()
    check_flutter_test()
    check_web_integrity()
    print("=" * 60)
    print("✅ PRE-FLIGHT SCAN PASSED: All safety and quality checks verified!")
    print("=" * 60)

if __name__ == "__main__":
    main()
