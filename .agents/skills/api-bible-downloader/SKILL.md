---
name: api-bible-downloader
description: >-
  Retrieves Scripture text, streaming audio URLs, and chapter audio from API.Bible
  safely using dynamic environment variables and strict copyright guardrails.
---

# API.Bible Downloader & Audio Query Skill

Use this skill when fetching Scripture text or audio from the API.Bible REST API.

---

## 1. Zero Plaintext Credentials Policy
- Always query using the environment variable `$API_BIBLE_KEY`.
- Under NO circumstances may an API key or token be hardcoded into code, test files, scripts, or documentation.

---

## 2. Copyright & Licensing Classification
- **Public Domain / Creative Commons (BSB, WEB)**:
  - Streaming audio: Allowed (`get-audio-url`).
  - Audio file download: Allowed for offline timestamp calibration (`download-audio`).
- **Proprietary / Commercial (NIV, Biblica, Zondervan)**:
  - Streaming audio: Allowed at runtime for ephemeral playback (`get-audio-url`).
  - Audio file download: **STRICTLY PROHIBITED**. The CLI tool `scripts/api_bible_fetch.sh` will reject download requests with exit code 2.

---

## 3. Tool Usage Examples
Use `scripts/api_bible_fetch.sh`:

```bash
# 1. Get signed ephemeral streaming URL
./scripts/api_bible_fetch.sh get-audio-url --translation BSB --book MAT --chapter 11

# 2. Download audio for open translation
./scripts/api_bible_fetch.sh download-audio --translation BSB --book MAT --chapter 11 --out /tmp/bsb_mat11.mp3

# 3. Probe audio duration and bitrate
./scripts/api_bible_fetch.sh probe-audio --translation WEB --book ROM --chapter 8

# 4. Fetch clean chapter text
./scripts/api_bible_fetch.sh get-text --translation BSB --book 1CO --chapter 13
```
