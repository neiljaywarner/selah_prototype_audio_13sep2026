#!/usr/bin/env python3
"""Fail if tracked files contain literal compile-time API keys.

Prints file, line, and secret name only. Never prints a secret value.
Scans the git index (what commit and CI would publish), not gitignored
local files such as dart_defines.local.json.
"""

from __future__ import annotations

import re
import subprocess
import sys

SECRET_NAMES = (
    "API_BIBLE_KEY",
    "APTABASE_KEY",
    "ESV_API_KEY",
    "POSTHOG_KEY",
    "POSTHOG_MEMVERSE_API_KEY",
    "DOORBELL_API_KEY",
    "USERORIENT_KEY",
    "GITHUB_FEEDBACK_TOKEN",
)

# Well-known token shapes. Placeholders like A-US-... do not match.
TOKEN_SHAPES = (
    ("aptabase", re.compile(r"A-(?:US|EU|SH)-[A-Za-z0-9]{8,}")),
    ("posthog", re.compile(r"phc_[A-Za-z0-9]{10,}")),
    ("aws-access-key", re.compile(r"AKIA[0-9A-Z]{16}")),
    (
        "private-key",
        re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----"),
    ),
)

_TOKEN = re.compile(r"[A-Za-z0-9][A-Za-z0-9_\-]{7,}\Z")
_PLACEHOLDER_WORDS = {
    "REDACTED",
    "NONE",
    "NULL",
    "TODO",
    "CHANGEME",
    "PLACEHOLDER",
    "EXAMPLE",
    "YOUR_KEY",
    "YOUR_API_KEY",
    "YOUR_APP_ID",
    "TEST-KEY",
    "FAKE",
}


def is_placeholder(value: str) -> bool:
    val = value.strip().strip(",").strip(";").strip(")")
    if not val or val in {"...", "…"}:
        return True
    if val.startswith(("$", "%", "<", "{{")):
        return True
    if "secrets." in val or val.startswith(":-"):
        return True
    if set(val) <= set(".*xX_-"):
        return True
    upper = val.upper()
    if upper in _PLACEHOLDER_WORDS or upper.startswith("YOUR_"):
        return True
    return False


def looks_like_secret(value: str) -> bool:
    if is_placeholder(value):
        return False
    return _TOKEN.fullmatch(value) is not None


def _assignment_patterns(name: str) -> tuple[re.Pattern[str], ...]:
    return (
        re.compile(rf"--dart-define={name}=(?P<val>[^\s\\]+)"),
        re.compile(rf"""[\"']{name}[\"']\s*:\s*[\"'](?P<val>[^\"']*)[\"']"""),
        re.compile(
            rf"""(?:^|[\s{{])(?:export\s+)?{name}\s*=\s*[\"']?(?P<val>[^\s\"'\\#]+)"""
        ),
        re.compile(rf"(?:^|\s){name}\s*:\s*(?P<val>\S+)"),
    )


def findings_in_text(path: str, text: str) -> list[str]:
    findings: list[str] = []
    lines = text.splitlines()
    compiled = [(name, _assignment_patterns(name)) for name in SECRET_NAMES]
    for lineno, line in enumerate(lines, start=1):
        for name, patterns in compiled:
            for pattern in patterns:
                for match in pattern.finditer(line):
                    value = match.group("val")
                    if looks_like_secret(value):
                        findings.append(
                            f"{path}:{lineno} {name} assignment "
                            f"(value length {len(value)}, not printed)"
                        )
        for shape, pattern in TOKEN_SHAPES:
            for match in pattern.finditer(line):
                findings.append(
                    f"{path}:{lineno} {shape} token "
                    f"(length {len(match.group(0))}, not printed)"
                )
    return findings


def tracked_texts() -> list[tuple[str, str]]:
    listed = subprocess.check_output(["git", "ls-files", "-z"])
    paths = [p.decode() for p in listed.split(b"\0") if p]
    texts: list[tuple[str, str]] = []
    for path in paths:
        blob = subprocess.check_output(["git", "show", f":{path}"])
        if b"\0" in blob[:8000]:
            continue
        texts.append((path, blob.decode("utf-8", errors="replace")))
    return texts


def scan_index() -> list[str]:
    findings: list[str] = []
    for path, text in tracked_texts():
        if path == "dart_defines.local.json":
            findings.append(
                f"{path}:1 tracked local defines file "
                "(keep dart_defines.local.json gitignored)"
            )
        findings.extend(findings_in_text(path, text))
    return findings


def self_test() -> None:
    literal = "ab" * 8
    cases = [
        (f"--dart-define=API_BIBLE_KEY={literal}", True),
        ("--dart-define=API_BIBLE_KEY=$API_BIBLE_KEY", False),
        # Fake env interpolation. Do not copy a value from launch.json.
        ("--dart-define=API_BIBLE_KEY=${env:FAKE_KEY_XXXX}", False),
        ('"API_BIBLE_KEY": "YOUR_API_BIBLE_KEY"', False),
        ('"ESV_API_KEY": "' + ("cd" * 8) + '"', True),
        ("export ESV_API_KEY=...", False),
        ("API_BIBLE_KEY: ${{ secrets.API_BIBLE_KEY }}", False),
        ("prefix " + "A-US-" + "abcdefghij" + " suffix", True),
        ("e.g. A-US-...", False),
        ("e.g. phc_...", False),
        ("phc_" + "abcdefghijklmnop", True),
        (
            r"""m = re.search(r'ESV_API_KEY=["\x27]?([A-Za-z0-9_\-]+)["\x27]?', line)""",
            False,
        ),
        ("apiKey: 'test-key'", False),
    ]
    failed = False
    for text, expect_hit in cases:
        got = findings_in_text("fixture", text)
        if bool(got) != expect_hit:
            print(
                f"self-test failed: expected hit={expect_hit} got {len(got)}",
                file=sys.stderr,
            )
            failed = True
    if failed:
        sys.exit(2)


def main() -> None:
    self_test()
    findings = scan_index()
    if findings:
        print("Committed secret material detected (values not printed):", file=sys.stderr)
        for item in findings:
            print(f"  {item}", file=sys.stderr)
        sys.exit(1)
    print("No committed API key values found.")


if __name__ == "__main__":
    main()
