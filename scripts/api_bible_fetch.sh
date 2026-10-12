#!/usr/bin/env bash
# ==============================================================================
# Selah API.Bible CLI Audio & Text Fetcher
# ==============================================================================
# Safely queries API.Bible REST endpoints using dynamic $API_BIBLE_KEY.
# 
# COPYRIGHT & LICENSING COMPLIANCE:
# - PUBLIC DOMAIN / OPEN LICENSES (BSB, WEB):
#   Audio downloads to local disk are permitted solely for acoustic alignment
#   and offline timestamp generation.
# - PROPRIETARY / COMMERCIAL LICENSES (NIV, Biblica):
#   Downloading or storing audio MP3s locally is STRICTLY FORBIDDEN by license terms.
#   Only ephemeral streaming URLs (get-audio-url) are permitted at runtime.
#
# ZERO SECRETS POLICY:
# - Uses dynamic $API_BIBLE_KEY from environment.
# - Zero plaintext keys stored in repo, files, or git history.
# ==============================================================================
set -euo pipefail

if [[ -z "${API_BIBLE_KEY:-}" ]]; then
  echo "❌ Error: API_BIBLE_KEY environment variable is not set." >&2
  echo "Please export API_BIBLE_KEY='<your-api-bible-token>' and re-run." >&2
  exit 1
fi

BASE_URL="https://rest.api.bible/v1"

# API.Bible Translation Bible IDs
BSB_AUDIO_ID="aadc8a2f4bdb467b-01"  # Berean Standard Bible (Open / Creative Commons)
WEB_AUDIO_ID="105a06b6146d11e7-01"  # World English Bible (Public Domain)
NIV_AUDIO_ID="0d29bf705c488e0e-01"  # New International Version (Proprietary / Biblica)

BSB_TEXT_ID="bba9f40183526463-01"
WEB_TEXT_ID="9879dbb7cfe39e4d-01"
NIV_TEXT_ID="eng_niv"                # Text requires commercial API.Bible license grant

usage() {
  cat << EOF
Selah API.Bible Fetcher & Licensing Compliance Utility
Usage: $(basename "$0") <command> [options]

Commands:
  get-audio-url --translation <BSB|WEB|NIV> --book <BOOK> --chapter <N>
      Returns the signed S3 audio streaming URL for a given chapter.
      Permitted for all translations (ephemeral streaming only).

  download-audio --translation <BSB|WEB> --book <BOOK> --chapter <N> --out <PATH>
      Downloads the chapter MP3 file to local disk.
      ⚠️ STRICT COPYRIGHT GUARD: Permitted ONLY for Public Domain / Open translations (BSB, WEB).
      Attempts to download proprietary translations (e.g. NIV) will be REJECTED.

  probe-audio --translation <BSB|WEB|NIV> --book <BOOK> --chapter <N>
      Probes audio stream duration, bitrate, and sample rate using ffprobe without saving to disk.

  get-text --translation <BSB|WEB> --book <BOOK> --chapter <N>
      Fetches clean plaintext for the requested chapter.

Options:
  --translation <CODE>  Bible translation: BSB (default), WEB, or NIV
  --book <BOOK>         3-letter USFM book code (e.g., MAT, 1CO, ROM, PSA)
  --chapter <N>         Chapter number (e.g., 11, 13, 8, 23)
  --out <PATH>          Destination file path (required for download-audio)
  -h, --help            Display this help message

Examples:
  $(basename "$0") get-audio-url --translation BSB --book MAT --chapter 11
  $(basename "$0") download-audio --translation BSB --book MAT --chapter 11 --out /tmp/bsb_mat11.mp3
  $(basename "$0") probe-audio --translation WEB --book ROM --chapter 8
EOF
  exit 1
}

if [[ $# -eq 0 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
fi

COMMAND="$1"
shift

TRANSLATION="BSB"
BOOK=""
CHAPTER=""
OUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --translation)
      TRANSLATION="$(echo "$2" | tr '[:lower:]' '[:upper:]')"
      shift 2
      ;;
    --book)
      BOOK="$(echo "$2" | tr '[:lower:]' '[:upper:]')"
      shift 2
      ;;
    --chapter)
      CHAPTER="$2"
      shift 2
      ;;
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "$BOOK" || -z "$CHAPTER" ]]; then
  echo "❌ Error: --book and --chapter arguments are required." >&2
  exit 1
fi

case "$TRANSLATION" in
  BSB)
    AUDIO_ID="$BSB_AUDIO_ID"
    TEXT_ID="$BSB_TEXT_ID"
    IS_PROPRIETARY=false
    ;;
  WEB)
    AUDIO_ID="$WEB_AUDIO_ID"
    TEXT_ID="$WEB_TEXT_ID"
    IS_PROPRIETARY=false
    ;;
  NIV)
    AUDIO_ID="$NIV_AUDIO_ID"
    TEXT_ID="$NIV_TEXT_ID"
    IS_PROPRIETARY=true
    ;;
  *)
    echo "❌ Error: Unsupported translation '$TRANSLATION'. Supported: BSB, WEB, NIV." >&2
    exit 1
    ;;
esac

CHAPTER_ID="${BOOK}.${CHAPTER}"

case "$COMMAND" in
  get-audio-url)
    ENDPOINT="${BASE_URL}/audio-bibles/${AUDIO_ID}/chapters/${CHAPTER_ID}"
    RESPONSE=$(curl -s -f -H "api-key: ${API_BIBLE_KEY}" "$ENDPOINT")
    URL=$(echo "$RESPONSE" | jq -r '.data.resourceUrl // empty')
    if [[ -z "$URL" ]]; then
      echo "❌ Error: No resourceUrl returned for ${CHAPTER_ID} in ${TRANSLATION}." >&2
      exit 1
    fi
    echo "$URL"
    ;;

  download-audio)
    # STRICT COPYRIGHT COMPLIANCE GATE
    if [[ "$IS_PROPRIETARY" == "true" ]]; then
      echo "🛑 LEGAL / COPYRIGHT REJECTION:" >&2
      echo "Downloading audio for proprietary translation '$TRANSLATION' is strictly prohibited by license terms." >&2
      echo "Proprietary audio may ONLY be streamed ephemerally via 'get-audio-url' at playback time." >&2
      echo "Local caching/saving of '$TRANSLATION' MP3 files is blocked." >&2
      exit 2
    fi

    if [[ -z "$OUT_FILE" ]]; then
      echo "❌ Error: --out <PATH> is required for download-audio." >&2
      exit 1
    fi

    ENDPOINT="${BASE_URL}/audio-bibles/${AUDIO_ID}/chapters/${CHAPTER_ID}"
    RESPONSE=$(curl -s -f -H "api-key: ${API_BIBLE_KEY}" "$ENDPOINT")
    URL=$(echo "$RESPONSE" | jq -r '.data.resourceUrl // empty')
    if [[ -z "$URL" ]]; then
      echo "❌ Error: No resourceUrl returned for ${CHAPTER_ID} in ${TRANSLATION}." >&2
      exit 1
    fi

    mkdir -p "$(dirname "$OUT_FILE")"
    echo "⬇️ Downloading ${TRANSLATION} ${CHAPTER_ID} to ${OUT_FILE} (Public Domain / Open License)..."
    curl -sSL "$URL" -o "$OUT_FILE"
    echo "✅ Download complete: $(ls -lh "$OUT_FILE" | awk '{print $5}')"
    ;;

  probe-audio)
    ENDPOINT="${BASE_URL}/audio-bibles/${AUDIO_ID}/chapters/${CHAPTER_ID}"
    RESPONSE=$(curl -s -f -H "api-key: ${API_BIBLE_KEY}" "$ENDPOINT")
    URL=$(echo "$RESPONSE" | jq -r '.data.resourceUrl // empty')
    if [[ -z "$URL" ]]; then
      echo "❌ Error: No resourceUrl returned for ${CHAPTER_ID} in ${TRANSLATION}." >&2
      exit 1
    fi
    echo "🔍 Probing ${TRANSLATION} ${CHAPTER_ID} stream (ephemeral probe, zero disk write)..."
    ffprobe -i "$URL" -hide_banner
    DUR=$(ffprobe -i "$URL" -show_entries format=duration -v quiet -of csv="p=0")
    echo "⏱️ Total Duration: ${DUR} seconds"
    ;;

  get-text)
    if [[ "$IS_PROPRIETARY" == "true" ]]; then
      echo "⚠️ Notice: '$TRANSLATION' text queries require explicit commercial license grant on API.Bible." >&2
    fi
    ENDPOINT="${BASE_URL}/bibles/${TEXT_ID}/chapters/${CHAPTER_ID}?content-type=text"
    RESPONSE=$(curl -s -f -H "api-key: ${API_BIBLE_KEY}" "$ENDPOINT")
    echo "$RESPONSE" | jq -r '.data.content // empty'
    ;;

  *)
    echo "Unknown command: $COMMAND" >&2
    usage
    ;;
esac
