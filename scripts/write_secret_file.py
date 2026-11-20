#!/usr/bin/env python3
"""Copy one environment variable to a mode-0600 file. Never print the value."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    value = os.environ.get(args.env, "")
    if not value:
        print(
            f"{args.env} is empty. Add it under Settings → Secrets and variables → Actions. "
            "The value is not printed.",
            file=sys.stderr,
        )
        return 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(value, encoding="utf-8")
    os.chmod(args.output, 0o600)
    print(f"Wrote {args.env} to the output path (contents hidden).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
