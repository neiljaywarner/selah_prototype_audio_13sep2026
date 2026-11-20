#!/usr/bin/env python3
"""Decode the CI keystore and write android/key.properties. Never print secrets."""

from __future__ import annotations

import argparse
import base64
import binascii
import os
import sys
from pathlib import Path


def _required(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        print(
            f"{name} is empty. Add it under Settings → Secrets and variables → Actions. "
            "The value is not printed.",
            file=sys.stderr,
        )
        sys.exit(1)
    return value


def _property(value: str) -> str:
    """Escape a value for java.util.Properties.load.

    A leading space has to be escaped because load() discards unescaped
    whitespace after '='. Tabs and form feeds are encoded the same way
    Properties.store encodes them.
    """
    encoded: list[str] = []
    for index, char in enumerate(value):
        if char == "\\":
            encoded.append("\\\\")
        elif char == "\n":
            encoded.append("\\n")
        elif char == "\r":
            encoded.append("\\r")
        elif char == "\t":
            encoded.append("\\t")
        elif char == "\f":
            encoded.append("\\f")
        elif char == " " and index == 0:
            encoded.append("\\ ")
        else:
            encoded.append(char)
    return "".join(encoded)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--properties-file", type=Path, required=True)
    parser.add_argument("--keystore-file", type=Path, required=True)
    parser.add_argument("--store-file-property", required=True)
    args = parser.parse_args()

    encoded = _required("ANDROID_KEYSTORE_BASE64")
    store_password = _required("ANDROID_KEYSTORE_PASSWORD")
    key_password = _required("ANDROID_KEY_PASSWORD")
    alias = _required("ANDROID_KEY_ALIAS")

    try:
        raw = base64.b64decode("".join(encoded.split()), validate=True)
    except (binascii.Error, ValueError):
        print(
            "ANDROID_KEYSTORE_BASE64 is not valid base64. "
            "Encode the keystore with: base64 -w 0 <keystore-file>",
            file=sys.stderr,
        )
        return 1
    if not raw:
        print(
            "ANDROID_KEYSTORE_BASE64 decoded to an empty keystore.",
            file=sys.stderr,
        )
        return 1

    args.keystore_file.parent.mkdir(parents=True, exist_ok=True)
    args.properties_file.parent.mkdir(parents=True, exist_ok=True)
    args.keystore_file.write_bytes(raw)
    os.chmod(args.keystore_file, 0o600)
    properties = "\n".join(
        [
            f"storePassword={_property(store_password)}",
            f"keyPassword={_property(key_password)}",
            f"keyAlias={_property(alias)}",
            f"storeFile={args.store_file_property}",
            "",
        ]
    )
    args.properties_file.write_text(properties, encoding="utf-8")
    os.chmod(args.properties_file, 0o600)
    print("Wrote Android signing files (contents hidden).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
