#!/usr/bin/env bash
# ==============================================================================
# Selah Scripture Audio Meditation — Automated Android Release & Distribution
# ==============================================================================
# Usage:
#   ./scripts/distribute_android_release.sh [OPTIONS]
#
# Options:
#   --notes "<string>"     Custom release notes to include with the distribution.
#   --groups "<alias>"     Comma-separated tester group aliases (default: core-testers).
#   --dry-run              Build the release APK but skip uploading to Firebase.
#   --help, -h             Show this help message.
# ==============================================================================

set -euo pipefail

FIREBASE_APP_ID="1:228765786696:android:edf812ba8fc701fe382e7d"
DEFAULT_GROUPS="core-testers"
PROJECT_ID="selahwordapp"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

DRY_RUN=false
CUSTOM_NOTES=""
TARGET_GROUPS="$DEFAULT_GROUPS"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --notes)
      CUSTOM_NOTES="$2"
      shift 2
      ;;
    --groups)
      TARGET_GROUPS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      echo "Usage: ./scripts/distribute_android_release.sh [--notes '<notes>'] [--groups '<group>'] [--dry-run]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$WORKSPACE_ROOT"

echo "=== Selah Android Release & Distribution Pipeline ==="
echo "Workspace: $WORKSPACE_ROOT"
echo "Target Groups: $TARGET_GROUPS"

# 1. Dependency checks
if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter CLI not found in PATH." >&2
  exit 1
fi

if [ "$DRY_RUN" = false ] && ! command -v firebase >/dev/null 2>&1; then
  echo "Error: firebase CLI not found in PATH." >&2
  exit 1
fi

# 2. Extract current pubspec version
APP_VERSION="$(grep -E '^version:' pubspec.yaml | head -n 1 | awk '{print $2}')"
echo "Current Version: $APP_VERSION"

# 3. Assemble Release Notes
TIMESTAMP="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
COMMIT_HASH="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

RELEASE_NOTES="Selah Scripture Audio Meditation v${APP_VERSION}
Release Timestamp: ${TIMESTAMP}
Git Commit: ${COMMIT_HASH} (${GIT_BRANCH})
Target Audience: ${TARGET_GROUPS}"

if [ -n "$CUSTOM_NOTES" ]; then
  RELEASE_NOTES="${RELEASE_NOTES}

Highlights:
${CUSTOM_NOTES}"
fi

# 4. Clean & Build Release APK
echo "--- Compiling Flutter Release APK ---"
BUILD_ARGS=()
if [ -n "${API_BIBLE_KEY:-}" ]; then
  echo "Found API_BIBLE_KEY in environment; passing via --dart-define"
  BUILD_ARGS+=(--dart-define=API_BIBLE_KEY="$API_BIBLE_KEY")
fi
if [ -n "${APTABASE_KEY:-}" ]; then
  echo "Found APTABASE_KEY in environment; passing via --dart-define"
  BUILD_ARGS+=(--dart-define=APTABASE_KEY="$APTABASE_KEY")
fi
if [ -n "${POSTHOG_KEY:-}" ]; then
  echo "Found POSTHOG_KEY in environment; passing via --dart-define"
  BUILD_ARGS+=(--dart-define=POSTHOG_KEY="$POSTHOG_KEY")
fi
if [ -n "${ESV_API_KEY:-}" ]; then
  echo "Found ESV_API_KEY in environment; passing via --dart-define"
  BUILD_ARGS+=(--dart-define=ESV_API_KEY="$ESV_API_KEY")
fi
flutter build apk --release "${BUILD_ARGS[@]}"

if [ ! -f "$APK_PATH" ]; then
  echo "Error: Expected APK file not found at $APK_PATH" >&2
  exit 1
fi

FILE_SIZE="$(du -h "$APK_PATH" | awk '{print $1}')"
echo "Release APK compiled successfully ($FILE_SIZE at $APK_PATH)"

# 5. Distribute via Firebase App Distribution
if [ "$DRY_RUN" = true ]; then
  echo "--- Dry run enabled: Skipping Firebase upload ---"
  echo "Release notes would have been:"
  echo "$RELEASE_NOTES"
  echo "=== Dry Run Complete ==="
  exit 0
fi

echo "--- Distributing to Firebase App Distribution ---"
firebase appdistribution:distribute "$APK_PATH" \
  --app "$FIREBASE_APP_ID" \
  --project "$PROJECT_ID" \
  --groups "$TARGET_GROUPS" \
  --testers "njwandroid@gmail.com,neilwarner@gmail.com" \
  --release-notes "$RELEASE_NOTES"

echo "=== Release Distributed Successfully to $TARGET_GROUPS ==="
