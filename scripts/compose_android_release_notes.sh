#!/usr/bin/env bash
# Print Firebase App Distribution release notes.
# COMMIT_SUBJECT / COMMIT_BODY / COMMIT_SHA / APP_VERSION / NOTES_OVERRIDE
# may be provided by the caller. Nothing in the commit text is executed.
set -euo pipefail

version="${APP_VERSION:-unknown}"
subject="${COMMIT_SUBJECT:-}"
body="${COMMIT_BODY:-}"
sha="${COMMIT_SHA:-unknown}"
override="${NOTES_OVERRIDE:-}"

if [ -z "$subject" ] && command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  subject="$(git log -1 --pretty=%s)"
  body="$(git log -1 --pretty=%b)"
  sha="$(git rev-parse HEAD)"
fi

title="$subject"
if [[ "$subject" == Merge\ pull\ request\ \#* ]]; then
  title=""
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "${line//[[:space:]]/}" ]; then
      title="$line"
      break
    fi
  done <<< "$body"
  if [ -z "$title" ]; then
    title="$subject"
  fi
fi

if [ -n "$override" ]; then
  title="$override"
fi

printf '%s\n' "Selah Scripture Audio Meditation v${version}"
printf '%s\n' "$title"
printf '\n'
printf '%s\n' "Commit: ${sha}"
