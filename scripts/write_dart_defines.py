#!/usr/bin/env python3
"""Write a Flutter --dart-define-from-file JSON object from optional secrets.

Only the allowlisted keys used by the preview workflow are read. Empty values
are omitted so the compile-time default stays REDACTED. Values are never printed.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

ALLOWLIST = (
    "API_BIBLE_KEY",
    "APTABASE_KEY",
    "POSTHOG_KEY",
    "ESV_API_KEY",
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    defines: dict[str, str] = {}
    for name in ALLOWLIST:
        value = os.environ.get(name, "")
        if value:
            defines[name] = value
            print(f"Passing --dart-define={name} (value hidden)")
        else:
            print(f"Secret {name} is unset; leaving the compile-time default")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(defines, indent=2) + "\n", encoding="utf-8")
    os.chmod(args.output, 0o600)
    return 0


if __name__ == "__main__":
    sys.exit(main())
