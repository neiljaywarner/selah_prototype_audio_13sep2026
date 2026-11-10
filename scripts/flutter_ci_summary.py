#!/usr/bin/env python3
"""Summarize flutter analyze, flutter test, and lcov for humans and GitHub.

Line coverage ignores generated files (*.g.dart, *.freezed.dart, l10n).
The minimum is the COVERAGE_MIN environment variable. Raise that one number
as the suite grows. The process exits non-zero when analyze failed, tests
failed, or coverage is under the minimum.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path


def _skip(path: str) -> bool:
    name = path.replace("\\", "/").split("/")[-1]
    lowered = path.replace("\\", "/")
    return (
        name.endswith(".g.dart")
        or name.endswith(".freezed.dart")
        or "/l10n/" in lowered
        or name.endswith(".l10n.dart")
    )


def coverage(lcov_path: Path) -> tuple[int, int, float]:
    hit = total = 0
    current = ""
    if not lcov_path.is_file():
        return 0, 0, 0.0
    for raw in lcov_path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if line.startswith("SF:"):
            current = line[3:]
        elif line.startswith("DA:") and current and not _skip(current):
            if "/lib/" not in current.replace("\\", "/") and not current.replace("\\", "/").startswith("lib/"):
                continue
            count = int(line.split(",")[1])
            total += 1
            if count > 0:
                hit += 1
    percent = (100.0 * hit / total) if total else 0.0
    return hit, total, percent


def analyze_issues(path: Path) -> tuple[int, str]:
    if not path.is_file():
        return 0, "analyze output missing"
    text = path.read_text(encoding="utf-8", errors="replace")
    issues = 0
    for line in text.splitlines():
        if " • " in line and (" error •" in line or " warning •" in line or " info •" in line):
            issues += 1
        elif line.startswith("error •") or line.startswith("warning •") or line.startswith("info •"):
            issues += 1
    if "No issues found" in text:
        issues = 0
    status = "clean" if issues == 0 and "No issues found" in text else f"{issues} issue(s)"
    return issues, status


def test_counts(path: Path) -> dict[str, int]:
    counts = {"passed": 0, "failed": 0, "skipped": 0}
    if not path.is_file():
        return counts
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        raw = raw.strip()
        if not raw.startswith("{"):
            continue
        try:
            event = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if event.get("type") != "testDone":
            continue
        if event.get("hidden") is True:
            continue
        if event.get("skipped") is True:
            counts["skipped"] += 1
            continue
        result = event.get("result")
        if result == "success":
            counts["passed"] += 1
        elif result in {"failure", "error"}:
            counts["failed"] += 1
    return counts


def _mark(ok: bool) -> str:
    return "pass" if ok else "FAIL"


def render(
    *,
    analyze_status: str,
    analyze_ok: bool,
    counts: dict[str, int],
    tests_ok: bool,
    hit: int,
    total: int,
    percent: float,
    minimum: float,
    coverage_ok: bool,
    seconds: str,
) -> str:
    return "\n".join(
        [
            "## Flutter CI",
            "",
            "| Check | Result | Detail |",
            "| --- | --- | --- |",
            f"| Analyze | {_mark(analyze_ok)} | {analyze_status} |",
            f"| Tests passed | {_mark(tests_ok)} | {counts['passed']} |",
            f"| Tests failed | {_mark(counts['failed'] == 0)} | {counts['failed']} |",
            f"| Tests skipped |  | {counts['skipped']} |",
            f"| Line coverage | {_mark(coverage_ok)} | {percent:.1f}% ({hit}/{total}) |",
            f"| Coverage minimum |  | {minimum:.1f}% |",
            f"| Duration |  | {seconds} |",
            "",
            "Coverage excludes `*.g.dart`, `*.freezed.dart`, and `l10n`.",
            "Raise the minimum with the `COVERAGE_MIN` environment variable.",
            "",
        ]
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--analyze", type=Path, required=True)
    parser.add_argument("--test-json", type=Path, required=True)
    parser.add_argument("--lcov", type=Path, required=True)
    parser.add_argument("--test-exit", type=Path)
    parser.add_argument("--analyze-exit", type=Path)
    parser.add_argument("--seconds", default="n/a")
    args = parser.parse_args()

    minimum = float(os.environ.get("COVERAGE_MIN", "0"))
    issues, analyze_status = analyze_issues(args.analyze)
    analyze_exit = 0
    if args.analyze_exit and args.analyze_exit.is_file():
        analyze_exit = int(args.analyze_exit.read_text().strip() or "0")
    analyze_ok = analyze_exit == 0 and issues == 0

    counts = test_counts(args.test_json)
    test_exit = 0
    if args.test_exit and args.test_exit.is_file():
        test_exit = int(args.test_exit.read_text().strip() or "0")
    tests_ok = test_exit == 0 and counts["failed"] == 0 and counts["passed"] > 0

    hit, total, percent = coverage(args.lcov)
    coverage_ok = total > 0 and percent + 1e-9 >= minimum

    body = render(
        analyze_status=analyze_status,
        analyze_ok=analyze_ok,
        counts=counts,
        tests_ok=tests_ok,
        hit=hit,
        total=total,
        percent=percent,
        minimum=minimum,
        coverage_ok=coverage_ok,
        seconds=args.seconds,
    )
    print(body)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(body)

    if not analyze_ok or not tests_ok or not coverage_ok:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
