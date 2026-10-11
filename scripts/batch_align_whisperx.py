#!/usr/bin/env python3
"""
SelahWord WhisperX Batch Timestamp Alignment Tool
Processes chapter audio files locally on macOS and outputs 2 KB JSON files.
"""

import os
import sys
import json
import argparse
import tempfile
import time
import requests

def parse_args():
    parser = argparse.ArgumentParser(description="Align Audio Bible Chapter to 2KB Verse Timestamp JSON using WhisperX")
    parser.add_argument("--translation", type=str, required=True, help="Bible translation code (e.g., WEB, BSB, NIV)")
    parser.add_argument("--book", type=str, required=True, help="3-letter book code (e.g., COL, JHN, PSL)")
    parser.add_argument("--chapter", type=int, required=True, help="Chapter number (e.g., 1)")
    parser.add_argument("--audio_source", type=str, required=True, help="Local MP3 path OR HTTP Audio Stream URL")
    parser.add_argument("--output_dir", type=str, default="assets/timestamps", help="Base output directory for asset timestamps")
    return parser.parse_args()

def download_temp_audio(url: str) -> str:
    print(f"📥 Downloading temporary audio stream: {url[:60]}...")
    temp_file = tempfile.NamedTemporaryFile(suffix=".mp3", delete=False)
    response = requests.get(url, stream=True, timeout=30)
    response.raise_for_status()
    for chunk in response.iter_content(chunk_size=16384):
        temp_file.write(chunk)
    temp_file.close()
    return temp_file.name

def process_alignment(audio_path: str, book: str, chapter: int):
    import whisperx

    print("⚡ Initializing WhisperX on Mac CPU (int8 quant)...")
    device = "cpu"
    batch_size = 8
    compute_type = "int8"

    print("🎵 Loading audio file into PyTorch pipeline...")
    audio = whisperx.load_audio(audio_path)

    print("🧠 Running Whisper transcription...")
    model = whisperx.load_model("base", device, compute_type=compute_type)
    result = model.transcribe(audio, batch_size=batch_size)

    print("🎯 Loading phoneme alignment model...")
    model_a, metadata = whisperx.load_align_model(language_code=result["language"], device=device)
    aligned_result = whisperx.align(result["segments"], model_a, metadata, audio, device, return_char_alignments=False)

    timestamps = []
    verse_counter = 1

    for segment in aligned_result.get("segments", []):
        text_clean = segment.get("text", "").strip()
        if not text_clean:
            continue

        start_ms = int(segment.get("start", 0) * 1000)
        end_ms = int(segment.get("end", 0) * 1000)

        timestamps.append({
            "verse": verse_counter,
            "text": text_clean,
            "startMs": start_ms,
            "endMs": end_ms
        })
        verse_counter += 1

    return timestamps

def main():
    args = parse_args()
    start_time = time.time()

    temp_audio_path = None
    if args.audio_source.startswith("http://") or args.audio_source.startswith("https://"):
        temp_audio_path = download_temp_audio(args.audio_source)
        working_audio_path = temp_audio_path
    else:
        working_audio_path = args.audio_source

    if not os.path.exists(working_audio_path):
        print(f"❌ Error: Audio source not found at {working_audio_path}")
        sys.exit(1)

    try:
        timestamps = process_alignment(working_audio_path, args.book, args.chapter)

        # Output folder format: assets/timestamps/WEB/
        out_folder = os.path.join(args.output_dir, args.translation.upper())
        os.makedirs(out_folder, exist_ok=True)

        # File name format: COL_1.json
        out_file_name = f"{args.book.upper()}_{args.chapter}.json"
        out_path = os.path.join(out_folder, out_file_name)

        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(timestamps, f, indent=2, ensure_ascii=False)

        file_size_kb = os.path.getsize(out_path) / 1024.0
        elapsed_sec = time.time() - start_time

        print(f"✅ Success! Created timestamp asset: {out_path} ({file_size_kb:.2f} KB) in {elapsed_sec:.1f}s")

    finally:
        if temp_audio_path and os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)
            print("🧹 Removed temporary MP3 file.")

if __name__ == "__main__":
    main()
