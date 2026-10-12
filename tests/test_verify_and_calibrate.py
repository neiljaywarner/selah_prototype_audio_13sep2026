#!/usr/bin/env python3
"""
Unit tests for Selah Audio Timestamp Verification & Calibration Engine (scripts/verify_and_calibrate_timestamps.py)
"""

import unittest
import sys
import os

# Add scripts directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts")))

from verify_and_calibrate_timestamps import (
    validate_schema_and_monotonicity,
    analyze_speech_rates,
    check_boundary_in_silence,
    calibrate_boundaries,
    MIN_HUMAN_WPS,
    MAX_HUMAN_WPS,
)

class TestVerifyAndCalibrate(unittest.TestCase):
    def test_valid_timestamps_pass_validation(self):
        verses = [
            {"verse": 1, "text": "In the beginning God created the heavens and the earth.", "startMs": 0, "endMs": 4000},
            {"verse": 2, "text": "Now the earth was formless and void.", "startMs": 4500, "endMs": 8500},
        ]
        errors = validate_schema_and_monotonicity(verses)
        self.assertEqual(len(errors), 0, f"Expected 0 errors, got: {errors}")

    def test_inverted_boundaries_fail_validation(self):
        verses = [
            {"verse": 1, "text": "Test verse", "startMs": 5000, "endMs": 4000},
        ]
        errors = validate_schema_and_monotonicity(verses)
        self.assertGreater(len(errors), 0)
        self.assertTrue(any("Inverted boundary" in err for err in errors))

    def test_overlapping_verses_fail_validation(self):
        verses = [
            {"verse": 1, "text": "First verse", "startMs": 1000, "endMs": 5000},
            {"verse": 2, "text": "Second verse", "startMs": 4000, "endMs": 8000},  # Overlaps by 1000ms (>250ms tolerance)
        ]
        errors = validate_schema_and_monotonicity(verses)
        self.assertGreater(len(errors), 0)
        self.assertTrue(any("Overlaps previous verse" in err for err in errors))

    def test_non_sequential_verse_numbering_fails(self):
        verses = [
            {"verse": 2, "text": "Second verse", "startMs": 1000, "endMs": 5000},
            {"verse": 1, "text": "First verse", "startMs": 5500, "endMs": 9000},
        ]
        errors = validate_schema_and_monotonicity(verses)
        self.assertGreater(len(errors), 0)
        self.assertTrue(any("Non-sequential" in err for err in errors))

    def test_speech_rate_analysis_flags_unrealistic_speeds(self):
        # 10 words in 100ms = 100 WPS (superhuman fast)
        too_fast = [{"verse": 1, "text": "one two three four five six seven eight nine ten", "startMs": 0, "endMs": 100}]
        # 2 words in 20 seconds = 0.1 WPS (super slow / hung audio)
        too_slow = [{"verse": 1, "text": "hello world", "startMs": 0, "endMs": 20000}]
        # Normal pacing: 10 words in 4 seconds = 2.5 WPS
        normal = [{"verse": 1, "text": "one two three four five six seven eight nine ten", "startMs": 0, "endMs": 4000}]

        res_fast = analyze_speech_rates(too_fast)
        self.assertTrue(res_fast[0]["is_suspicious"])
        self.assertGreater(res_fast[0]["wps"], MAX_HUMAN_WPS)

        res_slow = analyze_speech_rates(too_slow)
        self.assertTrue(res_slow[0]["is_suspicious"])
        self.assertLess(res_slow[0]["wps"], MIN_HUMAN_WPS)

        res_normal = analyze_speech_rates(normal)
        self.assertFalse(res_normal[0]["is_suspicious"])
        self.assertAlmostEqual(res_normal[0]["wps"], 2.5, places=1)

    def test_check_boundary_in_silence(self):
        pauses = [
            (3.8, 4.3, 0.5),   # Pause from 3800ms to 4300ms
            (8.5, 9.2, 0.7),   # Pause from 8500ms to 9200ms
        ]
        # 4000ms is inside pause 1 (3.8s to 4.3s)
        match = check_boundary_in_silence(4000, pauses)
        self.assertIsNotNone(match)
        self.assertEqual(match, (3.8, 4.3))

        # 6000ms is not in any pause
        match_none = check_boundary_in_silence(6000, pauses)
        self.assertIsNone(match_none)

    def test_calibrate_boundaries_snaps_to_silence_with_padding(self):
        verses = [
            {"verse": 1, "text": "Test verse", "startMs": 3950, "endMs": 8550},
        ]
        pauses = [
            (3.5, 3.9, 0.4),  # Pause ending at 3.9s -> start snaps to 3.9 + 0.05 = 3.95s (3950ms)
            (8.6, 9.1, 0.5),  # Pause starting at 8.6s -> end snaps to 8.6 - 0.05 = 8.55s (8550ms)
        ]
        calibrated = calibrate_boundaries(verses, pauses)
        self.assertEqual(calibrated[0]["startMs"], 3950)
        self.assertEqual(calibrated[0]["endMs"], 8550)

if __name__ == "__main__":
    unittest.main()
