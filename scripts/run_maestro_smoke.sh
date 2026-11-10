#!/usr/bin/env bash
# Run the Maestro smoke flows and keep screenshots, hierarchy dumps, and video
# frames in test_artifacts/maestro/<timestamp>/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/test_artifacts/maestro/$STAMP"
mkdir -p "$OUT"

if ! command -v maestro >/dev/null 2>&1; then
  echo "maestro is not on PATH. Install it from https://maestro.mobile.dev and retry." >&2
  exit 1
fi

cd "$ROOT"
maestro test \
  --debug-output "$OUT/debug" \
  --test-output-dir "$OUT" \
  --flatten-debug-output \
  --format JUNIT \
  --output "$OUT/junit.xml" \
  .maestro/smoke

echo "Maestro smoke artifacts: $OUT"
