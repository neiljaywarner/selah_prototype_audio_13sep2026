#!/usr/bin/env python3
"""
Selah Audio Timestamp Verification & Calibration Engine
======================================================
Analyzes Bible chapter audio against verse timestamps:
1. Validates schema, monotonicity, gap/overlap sanity.
2. Calculates human speech rates (WPS / WPM) based on verse word count.
3. Performs acoustic silence detection via FFmpeg (handles Drama and Non-Drama).
4. Detects boundary clipping errors (such as Matthew 11:28 starting at verse 19).
5. Snaps startMs and endMs boundaries to acoustic silence gaps.
6. Exports calibrated, production-ready timestamp JSON files.
"""

import os
import sys
import json
import re
import argparse
import subprocess
from typing import List, Dict, Any, Optional, Tuple

MIN_HUMAN_WPS = 1.0   # Words per second lower bound (60 WPM)
MAX_HUMAN_WPS = 4.8   # Words per second upper bound (288 WPM)
TYPICAL_WPS = 2.4     # Standard narrator pacing (144 WPM)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Verify and Calibrate Audio Timestamps using Acoustic Silence Detection and Speech Rate Heuristics"
    )
    parser.add_argument("--json", type=str, required=True, help="Path to existing verse timestamp JSON file")
    parser.add_argument("--audio", type=str, required=False, help="Local MP3 path OR HTTP/S3 audio stream URL")
    parser.add_argument("--noise-thresh", type=str, default="-28dB", help="FFmpeg silence detection noise threshold (e.g. -28dB for clean BSB, -20dB for drama WEB)")
    parser.add_argument("--min-silence", type=float, default=0.30, help="Minimum silence duration in seconds (default: 0.30s)")
    parser.add_argument("--calibrate", action="store_true", help="Snap timestamp boundaries to acoustic silence pauses and output updated JSON")
    parser.add_argument("--out", type=str, required=False, help="Output path for calibrated JSON (defaults to overwriting input if --calibrate is set)")
    return parser.parse_args()


def load_timestamps(json_path: str) -> List[Dict[str, Any]]:
    if not os.path.exists(json_path):
        raise FileNotFoundError(f"Timestamp file not found: {json_path}")
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError("Timestamp JSON root must be an array of verse objects.")
    return data


def validate_schema_and_monotonicity(verses: List[Dict[str, Any]]) -> List[str]:
    errors = []
    prev_end_ms = 0
    prev_verse_num = 0

    for idx, v in enumerate(verses):
        verse_num = v.get("verse")
        text = v.get("text", "")
        start_ms = v.get("startMs")
        end_ms = v.get("endMs")

        if not isinstance(verse_num, int) or verse_num <= 0:
            errors.append(f"Row {idx}: Invalid or missing 'verse' integer.")
        if not isinstance(text, str) or not text.strip():
            errors.append(f"Row {idx} (v{verse_num}): Empty or invalid 'text'.")
        if not isinstance(start_ms, int) or not isinstance(end_ms, int):
            errors.append(f"Row {idx} (v{verse_num}): 'startMs' and 'endMs' must be integers.")
            continue

        if start_ms >= end_ms:
            errors.append(f"Verse {verse_num}: Inverted boundary: startMs ({start_ms}) >= endMs ({end_ms}).")

        if idx > 0:
            if start_ms < prev_end_ms - 250:
                overlap_ms = prev_end_ms - start_ms
                errors.append(f"Verse {verse_num}: Overlaps previous verse by {overlap_ms}ms (starts at {start_ms}ms, prev ended at {prev_end_ms}ms).")
            if verse_num <= prev_verse_num:
                errors.append(f"Verse {verse_num}: Non-sequential verse numbering after {prev_verse_num}.")

        prev_end_ms = end_ms
        prev_verse_num = verse_num

    return errors


def analyze_speech_rates(verses: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    analysis = []
    for v in verses:
        verse_num = v.get("verse", 0)
        text = v.get("text", "")
        words = len(text.split())
        dur_sec = (v.get("endMs", 0) - v.get("startMs", 0)) / 1000.0
        wps = (words / dur_sec) if dur_sec > 0 else 0.0
        wpm = wps * 60.0

        is_suspicious = wps < MIN_HUMAN_WPS or wps > MAX_HUMAN_WPS
        analysis.append({
            "verse": verse_num,
            "words": words,
            "duration_sec": dur_sec,
            "wps": round(wps, 2),
            "wpm": round(wpm, 1),
            "is_suspicious": is_suspicious,
        })
    return analysis


def detect_silence_pauses(audio_source: str, noise_thresh: str = "-28dB", min_silence: float = 0.30) -> List[Tuple[float, float, float]]:
    """
    Executes FFmpeg silencedetect filter and parses (start_sec, end_sec, duration_sec) intervals.
    """
    cmd = [
        "ffmpeg",
        "-i", audio_source,
        "-af", f"silencedetect=noise={noise_thresh}:d={min_silence}",
        "-f", "null",
        "-"
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    pauses = []
    current_start = None

    for line in proc.stderr.splitlines():
        m_start = re.search(r"silence_start: ([\d\.]+)", line)
        if m_start:
            current_start = float(m_start.group(1))
        m_end = re.search(r"silence_end: ([\d\.]+)\s+\|\s+silence_duration: ([\d\.]+)", line)
        if m_end and current_start is not None:
            end_sec = float(m_end.group(1))
            dur_sec = float(m_end.group(2))
            pauses.append((current_start, end_sec, dur_sec))
            current_start = None

    return pauses


def get_audio_duration(audio_source: str) -> float:
    cmd = [
        "ffprobe",
        "-i", audio_source,
        "-show_entries", "format=duration",
        "-v", "quiet",
        "-of", "csv=p=0"
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    try:
        return float(proc.stdout.strip())
    except Exception:
        return 0.0


def check_boundary_in_silence(timestamp_ms: int, pauses: List[Tuple[float, float, float]], tolerance_sec: float = 0.20) -> Optional[Tuple[float, float]]:
    t_sec = timestamp_ms / 1000.0
    for start_p, end_p, _ in pauses:
        if (start_p - tolerance_sec) <= t_sec <= (end_p + tolerance_sec):
            return (start_p, end_p)
    return None


def calibrate_boundaries(verses: List[Dict[str, Any]], pauses: List[Tuple[float, float, float]]) -> List[Dict[str, Any]]:
    calibrated = []
    for idx, v in enumerate(verses):
        item = dict(v)
        start_ms = item["startMs"]
        end_ms = item["endMs"]
        start_sec = start_ms / 1000.0
        end_sec = end_ms / 1000.0

        # Find closest silence pause before/at start_sec
        best_start = start_sec
        for p_start, p_end, p_dur in pauses:
            if abs(p_end - start_sec) < 0.60:
                best_start = p_end + 0.05  # 50ms padding after silence
                break

        # Find closest silence pause after/at end_sec
        best_end = end_sec
        for p_start, p_end, p_dur in pauses:
            if abs(p_start - end_sec) < 0.60:
                best_end = p_start - 0.05  # 50ms before silence starts
                break

        item["startMs"] = int(round(best_start * 1000))
        item["endMs"] = int(round(best_end * 1000))
        calibrated.append(item)
    return calibrated


def main():
    args = parse_args()

    print(f"📄 Loading timestamp asset: {args.json}")
    verses = load_timestamps(args.json)

    print("\n🔍 Step 1: Validating schema and monotonicity...")
    errors = validate_schema_and_monotonicity(verses)
    if errors:
        print("❌ Schema & Monotonicity Errors Found:")
        for err in errors:
            print(f"   • {err}")
    else:
        print("✅ Schema & monotonicity: 100% Valid.")

    print("\n📊 Step 2: Speech rate pacing analysis:")
    rates = analyze_speech_rates(verses)
    for r in rates:
        status_flag = "⚠️ SUSPICIOUS" if r["is_suspicious"] else "✅ OK"
        print(f"   • Verse {r['verse']:2d}: {r['words']:2d} words in {r['duration_sec']:5.2f}s -> {r['wps']:4.2f} wps ({r['wpm']:5.1f} wpm) [{status_flag}]")

    if args.audio:
        print(f"\n🎧 Step 3: Acoustic analysis of audio: {args.audio}")
        total_duration = get_audio_duration(args.audio)
        print(f"   Total Audio Duration: {total_duration:.2f}s ({int(total_duration // 60)}m {int(total_duration % 60)}s)")

        first_start = verses[0].get("startMs", 0) / 1000.0
        last_end = verses[-1].get("endMs", 0) / 1000.0
        print(f"   Timestamp Excerpt Range: {first_start:.2f}s – {last_end:.2f}s (Span: {last_end - first_start:.2f}s)")

        if last_end > total_duration + 1.0:
            print(f"❌ FATAL ERROR: Excerpt ends at {last_end:.2f}s, exceeding total chapter audio duration {total_duration:.2f}s!")

        pauses = detect_silence_pauses(args.audio, noise_thresh=args.noise_thresh, min_silence=args.min_silence)
        print(f"   Detected {len(pauses)} acoustic pauses (noise threshold: {args.noise_thresh}, min: {args.min_silence}s)")

        print("\n🔍 Step 4: Boundary silence alignment audit:")
        for v in verses:
            v_num = v["verse"]
            s_match = check_boundary_in_silence(v["startMs"], pauses)
            e_match = check_boundary_in_silence(v["endMs"], pauses)

            s_status = f"✅ In pause ({s_match[0]:.2f}s–{s_match[1]:.2f}s)" if s_match else "⚠️ Lands in speech!"
            e_status = f"✅ In pause ({e_match[0]:.2f}s–{e_match[1]:.2f}s)" if e_match else "⚠️ Lands in speech!"
            print(f"   • Verse {v_num:2d} start ({v['startMs']}ms): {s_status}")
            print(f"   • Verse {v_num:2d} end   ({v['endMs']}ms): {e_status}")

        if args.calibrate:
            print("\n🛠️ Step 5: Calibrating boundaries to acoustic silence...")
            calibrated = calibrate_boundaries(verses, pauses)
            out_file = args.out if args.out else args.json
            with open(out_file, "w", encoding="utf-8") as f:
                json.dump(calibrated, f, indent=2, ensure_ascii=False)
            print(f"✅ Calibrated timestamp file written to: {out_file}")

    print("\n🏁 Validation completed.")
    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
