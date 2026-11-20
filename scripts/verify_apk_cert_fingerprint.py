#!/usr/bin/env python3
"""Compare an APK signing certificate with web/.well-known/assetlinks.json.

Exit 0 when the certificate matches a listed SHA-256 fingerprint.
Exit 1 before any upload when it does not. Fingerprints are public.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


def normalize(value: str) -> str:
    return re.sub(r"[^0-9a-f]", "", value.lower())


def colonize(hex_digits: str) -> str:
    return ":".join(
        hex_digits[i : i + 2] for i in range(0, len(hex_digits), 2)
    ).upper()


def fingerprints_in_text(text: str) -> list[str]:
    found: list[str] = []
    pattern = re.compile(r"SHA-?256[^:\n]*:\s*([0-9A-Fa-f:]+)")
    for match in pattern.finditer(text):
        digits = normalize(match.group(1))
        if len(digits) == 64 and digits not in found:
            found.append(digits)
    return found


def load_assetlinks(path: Path) -> tuple[list[str], list[str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    normalized: list[str] = []
    originals: list[str] = []
    for statement in data:
        target = statement.get("target") or {}
        for fingerprint in target.get("sha256_cert_fingerprints") or []:
            text = str(fingerprint)
            originals.append(text)
            digits = normalize(text)
            if len(digits) == 64:
                normalized.append(digits)
    if not normalized:
        raise SystemExit(f"No SHA-256 fingerprint in {path}")
    return normalized, originals


def _run(command: list[str]) -> subprocess.CompletedProcess[str] | None:
    try:
        return subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return None


def apksigner_candidates() -> list[Path]:
    roots: list[Path] = []
    for key in ("ANDROID_SDK_ROOT", "ANDROID_HOME"):
        value = os.environ.get(key)
        if value:
            roots.append(Path(value))
    home = Path.home()
    roots.extend(
        [
            home / "Android" / "Sdk",
            home / "Android" / "sdk",
            Path("/usr/local/lib/android/sdk"),
        ]
    )
    tools: list[Path] = []
    for root in roots:
        build_tools = root / "build-tools"
        if not build_tools.is_dir():
            continue
        tools.extend(sorted(build_tools.glob("*/apksigner"), reverse=True))
    return tools


def certificate_text_from_apk(apk: Path) -> str:
    chunks: list[str] = []
    for apksigner in apksigner_candidates():
        result = _run([str(apksigner), "verify", "--print-certs", str(apk)])
        if result is None:
            continue
        text = f"{result.stdout}\n{result.stderr}"
        if fingerprints_in_text(text):
            return text
        chunks.append(text)
    keytool = _run(["keytool", "-printcert", "-jarfile", str(apk)])
    if keytool is not None:
        text = f"{keytool.stdout}\n{keytool.stderr}"
        if fingerprints_in_text(text):
            return text
        chunks.append(text)
    details = "\n".join(chunk.strip() for chunk in chunks if chunk.strip())
    message = (
        "Could not read an SHA-256 certificate from the APK. "
        "Install Android build-tools (apksigner) or a JDK (keytool)."
    )
    if details:
        message = f"{message}\n{details}"
    raise SystemExit(message)


def main() -> int:
    parser = argparse.ArgumentParser()
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--cert-text", type=Path)
    source.add_argument("--apk", type=Path)
    parser.add_argument("--assetlinks", type=Path, required=True)
    args = parser.parse_args()

    if not args.assetlinks.is_file():
        print(f"Missing assetlinks file: {args.assetlinks}", file=sys.stderr)
        return 1
    expected, originals = load_assetlinks(args.assetlinks)

    if args.cert_text is not None:
        if not args.cert_text.is_file():
            print(f"Missing certificate text: {args.cert_text}", file=sys.stderr)
            return 1
        text = args.cert_text.read_text(encoding="utf-8")
    else:
        if not args.apk.is_file():
            print(f"Missing APK: {args.apk}", file=sys.stderr)
            return 1
        text = certificate_text_from_apk(args.apk)

    actuals = fingerprints_in_text(text)
    if not actuals:
        print(
            "No SHA-256 certificate fingerprint found. Refusing to continue.",
            file=sys.stderr,
        )
        return 1
    if any(item in expected for item in actuals):
        print("APK certificate matches assetlinks.json.")
        return 0

    print(
        "Signing certificate does not match web/.well-known/assetlinks.json.",
        file=sys.stderr,
    )
    for item in actuals:
        print(f"APK SHA-256: {colonize(item)} ({item})", file=sys.stderr)
    print("Expected from assetlinks.json:", file=sys.stderr)
    for item in originals:
        print(item, file=sys.stderr)
    print(
        "Sign with the debug/FAD keystore whose SHA-256 is in that file, "
        "then upload. Refusing to distribute this APK.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
