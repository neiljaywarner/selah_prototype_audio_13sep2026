#!/usr/bin/env bash
# Local equivalent of the Flutter CI job. Writes logs under test_artifacts/flutter/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/test_artifacts/flutter"
mkdir -p "$OUT"
cd "$ROOT"

: "${COVERAGE_MIN:=0}"
export COVERAGE_MIN

start=$(date +%s)

set +e
flutter analyze --no-fatal-infos >"$OUT/analyze.txt" 2>&1
echo $? >"$OUT/analyze.exit"
flutter test --coverage --concurrency=2 --reporter json >"$OUT/test.json" 2>"$OUT/test.stderr"
echo $? >"$OUT/test.exit"
set -e

seconds=$(( $(date +%s) - start ))
python3 "$ROOT/scripts/flutter_ci_summary.py" \
  --analyze "$OUT/analyze.txt" \
  --analyze-exit "$OUT/analyze.exit" \
  --test-json "$OUT/test.json" \
  --test-exit "$OUT/test.exit" \
  --lcov "$ROOT/coverage/lcov.info" \
  --seconds "${seconds}s"

echo "Logs: $OUT"
echo "Coverage: $ROOT/coverage/lcov.info"
