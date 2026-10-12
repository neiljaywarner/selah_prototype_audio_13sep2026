#!/usr/bin/env python3
"""
Selah Scripture Passage Audio Alignment & Verification Utility (No Black Magic)
================================================================================
A generic, reproducible CLI tool that aligns Scripture verse excerpts against
full-chapter audio from API.Bible using:
1. Speech recognition word timestamps (faster-whisper).
2. Acoustic waveform silence pause detection (FFmpeg silencedetect).
3. First-word canonical verification (detects preambles and prior verses).
4. Human speech pacing gates (Words Per Second).
5. 2 KB JSON asset generation for Selah's karaoke player.

Usage:
    ./scripts/align_scripture_passage.py \
        --translation BSB \
        --book JHN \
        --chapter 3 \
        --start-verse 16 \
        --end-verse 17 \
        --out assets/timestamps/BSB/JHN_3.json
"""

import os
import sys
import json
import re
import argparse
import subprocess
from typing import Dict, List, Any, Optional, Tuple

sys.path.insert(0, os.path.dirname(__file__))
from verify_and_calibrate_timestamps import (
    detect_silence_pauses,
    validate_schema_and_monotonicity,
    analyze_speech_rates
)

def clean_word(w: str) -> str:
    return re.sub(r"[^\w]", "", w).lower()

def download_audio_if_needed(translation: str, book: str, chapter: int, local_path: Optional[str] = None) -> str:
    if local_path and os.path.exists(local_path):
        return local_path

    out_file = f"/tmp/{translation.lower()}_{book.lower()}_{chapter}.mp3"
    if os.path.exists(out_file) and os.path.getsize(out_file) > 50000:
        return out_file

    print(f"📥 Downloading {translation} {book} {chapter} audio via api_bible_fetch.sh...")
    cmd = [
        "./scripts/api_bible_fetch.sh",
        "download-audio",
        "--translation", translation,
        "--book", book,
        "--chapter", str(chapter),
        "--out", out_file
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0 or not os.path.exists(out_file):
        raise RuntimeError(f"Audio download failed for {translation} {book} {chapter}:\n{res.stderr}")
    return out_file

def align_passage(
    audio_path: str,
    translation: str,
    book: str,
    chapter: int,
    start_verse: int,
    end_verse: int,
    raw_verses: List[Dict[str, Any]],
    noise_thresh: str = "-28dB"
) -> List[Dict[str, Any]]:
    from faster_whisper import WhisperModel

    print(f"🧠 Loading whisper base model for acoustic alignment...")
    model = WhisperModel("base.en", device="cpu", compute_type="int8")

    print(f"🎙️  Transcribing {audio_path}...")
    segments, info = model.transcribe(audio_path, beam_size=1, word_timestamps=True)
    all_words = []
    for s in segments:
        if s.words:
            all_words.extend(s.words)

    print(f"   Transcribed {len(all_words)} words across {info.duration:.1f}s audio.")

    # Silence pause detection via FFmpeg
    pauses = detect_silence_pauses(audio_path, noise_thresh=noise_thresh, min_silence=0.25)
    print(f"   Detected {len(pauses)} waveform silence pauses ({noise_thresh}).")

    calibrated_verses = []
    for item in raw_verses:
        v_num = item["verse"]
        text = item["text"]
        v_words = text.split()
        first_w = clean_word(v_words[0])
        last_w = clean_word(v_words[-1])

        best_start = None
        best_end = None

        for idx, w in enumerate(all_words):
            if clean_word(w.word) == first_w:
                # Check next 2 words match to avoid coincidence
                if idx + 2 < len(all_words):
                    next_1 = clean_word(all_words[idx+1].word)
                    next_2 = clean_word(all_words[idx+2].word)
                    target_1 = clean_word(v_words[1]) if len(v_words) > 1 else ""
                    target_2 = clean_word(v_words[2]) if len(v_words) > 2 else ""
                    if (not target_1 or next_1 == target_1) and (not target_2 or next_2 == target_2):
                        best_start = w.start
                        # Search forward for verse end word
                        for j in range(idx, min(idx + len(v_words) + 20, len(all_words))):
                            if clean_word(all_words[j].word) == last_w:
                                best_end = all_words[j].end
                        break

        if best_start is None:
            raise ValueError(f"Could not locate spoken start for verse {v_num} ('{v_words[0]} {v_words[1]}...')")
        if best_end is None:
            best_end = best_start + (len(v_words) / 2.4)

        # Snap start to preceding silence pause end + 50ms padding
        snapped_start_ms = int(best_start * 1000)
        for p_start, p_end, _ in pauses:
            if abs(p_end - best_start) < 0.60:
                snapped_start_ms = int((p_end + 0.05) * 1000)
                break

        # Snap end to succeeding silence pause start - 50ms padding
        snapped_end_ms = int(best_end * 1000)
        for p_start, p_end, _ in pauses:
            if abs(p_start - best_end) < 0.60:
                snapped_end_ms = int((p_start - 0.05) * 1000)
                break

        if snapped_end_ms <= snapped_start_ms:
            snapped_end_ms = snapped_start_ms + int(len(v_words) / 2.3 * 1000)

        calibrated_verses.append({
            "verse": v_num,
            "text": text,
            "startMs": snapped_start_ms,
            "endMs": snapped_end_ms
        })

    return calibrated_verses

def main():
    parser = argparse.ArgumentParser(description="Align Scripture passage audio to 2KB JSON timestamps")
    parser.add_argument("--translation", type=str, required=True, choices=["BSB", "WEB"])
    parser.add_argument("--book", type=str, required=True)
    parser.add_argument("--chapter", type=int, required=True)
    parser.add_argument("--start-verse", type=int, required=True)
    parser.add_argument("--end-verse", type=int, required=True)
    parser.add_argument("--audio", type=str, help="Optional local path to MP3")
    parser.add_argument("--out", type=str, help="Output JSON path")
    args = parser.parse_args()

    from generate_level2_timestamps import LEVEL_2_DATA
    ch_key = f"{args.book.upper()}_{args.chapter}"
    if ch_key not in LEVEL_2_DATA[args.translation]:
        print(f"❌ Error: {ch_key} not in LEVEL_2_DATA bank.")
        sys.exit(1)

    all_ch_verses = LEVEL_2_DATA[args.translation][ch_key]
    target_verses = [v for v in all_ch_verses if args.start_verse <= v["verse"] <= args.end_verse]

    audio_path = download_audio_if_needed(args.translation, args.book.upper(), args.chapter, args.audio)
    noise_thresh = "-20dB" if args.translation == "WEB" else "-28dB"

    try:
        calibrated = align_passage(
            audio_path=audio_path,
            translation=args.translation,
            book=args.book.upper(),
            chapter=args.chapter,
            start_verse=args.start_verse,
            end_verse=args.end_verse,
            raw_verses=target_verses,
            noise_thresh=noise_thresh
        )

        errors = validate_schema_and_monotonicity(calibrated)
        rates = analyze_speech_rates(calibrated)

        print("\n📊 Alignment Summary:")
        for r in rates:
            print(f"   Verse {r['verse']}: {r['duration_sec']}s, {r['wps']} WPS ({'✅ OK' if not r['is_suspicious'] else '⚠️ SUSPICIOUS'})")

        if errors:
            print(f"❌ Schema errors: {errors}")
            sys.exit(1)

        out_path = args.out or f"assets/timestamps/{args.translation}/{ch_key}.json"
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(calibrated, f, indent=2, ensure_ascii=False)

        print(f"\n✅ Production timestamp asset written: {out_path} ({os.path.getsize(out_path)/1024:.2f} KB)")

    finally:
        if audio_path.startswith("/tmp") and os.path.exists(audio_path):
            os.remove(audio_path)

if __name__ == "__main__":
    main()
