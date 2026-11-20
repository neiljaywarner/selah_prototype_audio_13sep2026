#!/usr/bin/env bash
# Exit 0 when every secret required to sign and upload an Android build is set.
# On failure, print secret names and what each one holds. Never print values.
set -euo pipefail

missing=()

require() {
  local name="$1"
  local help="$2"
  if [ -z "${!name:-}" ]; then
    missing+=("- ${name}: ${help}")
  fi
}

require ANDROID_KEYSTORE_BASE64 \
  "base64 of the keystore whose SHA-256 is listed in web/.well-known/assetlinks.json. For the current debug/FAD certificate, encode ~/.android/debug.keystore with: base64 -w 0."
require ANDROID_KEYSTORE_PASSWORD \
  "keystore store password. The standard Android debug keystore uses its well-known password."
require ANDROID_KEY_PASSWORD \
  "key password. The standard Android debug keystore uses its well-known password."
require ANDROID_KEY_ALIAS \
  "key alias. The standard Android debug keystore alias is androiddebugkey."
require FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP \
  "Firebase service account JSON for project selahwordapp. The preview workflow uses this same secret. Grant the account Firebase App Distribution Admin. Do not commit the JSON file."

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing GitHub Actions secrets. Add them under Settings → Secrets and variables → Actions." >&2
  echo "Names only; secret values are not printed." >&2
  printf '%s\n' "${missing[@]}" >&2
  exit 1
fi

echo "Required Android distribution secrets are set."
