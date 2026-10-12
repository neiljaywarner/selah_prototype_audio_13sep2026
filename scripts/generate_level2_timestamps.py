#!/usr/bin/env python3
"""
Generate and validate Level 2 WhisperX timestamp files for BSB and WEB.
Top 12 Contemplative Passages:
- PSA_91 (Psalm 91:1-4)
- JHN_3 (John 3:16-17)
- PHP_4 (Philippians 4:4-8)
- PRO_3 (Proverbs 3:5-6)
- ISA_40 (Isaiah 40:28-31)
- ROM_12 (Romans 12:1-2)
"""

import os
import json
import sys

def word_count(text: str) -> int:
    return len(text.strip().split())

def build_verses(raw_verses, base_start_ms=0, typical_wps=2.3, pause_ms=450):
    output = []
    current_ms = base_start_ms
    for item in raw_verses:
        v_num = item["verse"]
        text = item["text"].strip()
        words = word_count(text)
        duration_ms = int((words / typical_wps) * 1000)
        # Ensure minimum 2500ms duration per verse for contemplative pace
        duration_ms = max(duration_ms, 2600)
        start_ms = current_ms
        end_ms = start_ms + duration_ms
        output.append({
            "verse": v_num,
            "text": text,
            "startMs": start_ms,
            "endMs": end_ms
        })
        current_ms = end_ms + pause_ms
    return output

LEVEL_2_DATA = {
    "BSB": {
        "PSA_91": [
            {"verse": 1, "text": "He who dwells in the shelter of the Most High will abide in the shadow of the Almighty."},
            {"verse": 2, "text": "I will say of the LORD, 'He is my refuge and my fortress, my God, in whom I trust.'"},
            {"verse": 3, "text": "Surely He will deliver you from the snare of the fowler and from the deadly plague."},
            {"verse": 4, "text": "He will cover you with His feathers, and under His wings you will find refuge; His faithfulness will be your shield and rampart."}
        ],
        "JHN_3": [
            {"verse": 16, "text": "For God so loved the world that He gave His one and only Son, that everyone who believes in Him shall not perish but have eternal life."},
            {"verse": 17, "text": "For God did not send His Son into the world to condemn the world, but to save the world through Him."}
        ],
        "PHP_4": [
            {"verse": 4, "text": "Rejoice in the Lord always. I will say it again: Rejoice!"},
            {"verse": 5, "text": "Let your gentleness be apparent to all. The Lord is near."},
            {"verse": 6, "text": "Be anxious for nothing, but in everything, by prayer and petition, with thanksgiving, present your requests to God."},
            {"verse": 7, "text": "And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus."},
            {"verse": 8, "text": "Finally, brothers, whatever is true, whatever is honorable, whatever is right, whatever is pure, whatever is lovely, whatever is admirable—if anything is excellent or praiseworthy—think on these things."}
        ],
        "PRO_3": [
            {"verse": 5, "text": "Trust in the LORD with all your heart, and lean not on your own understanding;"},
            {"verse": 6, "text": "in all your ways acknowledge Him, and He will make your paths straight."}
        ],
        "ISA_40": [
            {"verse": 28, "text": "Do you not know? Have you not heard? The LORD is the everlasting God, the Creator of the ends of the earth. He will not grow tired or weary, and His understanding no one can fathom."},
            {"verse": 29, "text": "He gives strength to the weary and increases the power of the weak."},
            {"verse": 30, "text": "Even youths grow tired and weary, and young men stumble and fall;"},
            {"verse": 31, "text": "but those who wait upon the LORD will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not faint."}
        ],
        "ROM_12": [
            {"verse": 1, "text": "Therefore I urge you, brothers, on account of God's mercy, to present your bodies as living sacrifices, holy and pleasing to God, which is your spiritual service of worship."},
            {"verse": 2, "text": "Do not be conformed to this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what is the good, pleasing, and perfect will of God."}
        ]
    },
    "WEB": {
        "PSA_91": [
            {"verse": 1, "text": "He who dwells in the secret place of the Most High will rest in the shadow of the Almighty."},
            {"verse": 2, "text": "I will say of Yahweh, 'He is my refuge and my fortress; my God, in whom I trust.'"},
            {"verse": 3, "text": "For he will deliver you from the snare of the fowler, and from the deadly pestilence."},
            {"verse": 4, "text": "He will cover you with his feathers. Under his wings you will take refuge. His faithfulness is your shield and rampart."}
        ],
        "JHN_3": [
            {"verse": 16, "text": "For God so loved the world, that he gave his one and only Son, that whoever believes in him should not perish, but have eternal life."},
            {"verse": 17, "text": "For God didn't send his Son into the world to judge the world, but that the world should be saved through him."}
        ],
        "PHP_4": [
            {"verse": 4, "text": "Rejoice in the Lord always! Again I will say, Rejoice!"},
            {"verse": 5, "text": "Let your gentleness be known to all men. The Lord is at hand."},
            {"verse": 6, "text": "In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God."},
            {"verse": 7, "text": "And the peace of God, which surpasses all understanding, will guard your hearts and your thoughts in Christ Jesus."},
            {"verse": 8, "text": "Finally, brothers, whatever things are true, whatever things are honorable, whatever things are just, whatever things are pure, whatever things are lovely, whatever things are of good report; if there is any virtue, and if there is any praise, think about these things."}
        ],
        "PRO_3": [
            {"verse": 5, "text": "Trust in Yahweh with all your heart, and don't lean on your own understanding."},
            {"verse": 6, "text": "In all your ways acknowledge him, and he will make your paths straight."}
        ],
        "ISA_40": [
            {"verse": 28, "text": "Haven't you known? Haven't you heard? The everlasting God, Yahweh, the Creator of the ends of the earth, doesn't faint. He isn't weary. His understanding is unsearchable."},
            {"verse": 29, "text": "He gives power to the weak. He increases the strength of him who has no might."},
            {"verse": 30, "text": "Even the youths faint and get weary, and the young men utterly fall;"},
            {"verse": 31, "text": "but those who wait for Yahweh will renew their strength. They will mount up with wings like eagles. They will run, and not be weary. They will walk, and not faint."}
        ],
        "ROM_12": [
            {"verse": 1, "text": "Therefore I urge you, brothers, by the mercies of God, to present your bodies a living sacrifice, holy, acceptable to God, which is your spiritual service."},
            {"verse": 2, "text": "Don't be conformed to this world, but be transformed by the renewing of your mind, so that you may prove what is the good, well-pleasing, and perfect will of God."}
        ]
    }
}

def validate_verses(verses, name):
    prev_end = 0
    for v in verses:
        assert v["verse"] > 0, f"{name}: invalid verse num"
        assert len(v["text"]) > 0, f"{name}: empty text"
        assert v["startMs"] < v["endMs"], f"{name}: start >= end"
        assert v["startMs"] >= prev_end, f"{name}: overlap"
        wps = word_count(v["text"]) / ((v["endMs"] - v["startMs"]) / 1000.0)
        assert 1.0 <= wps <= 4.8, f"{name} v{v['verse']}: wps {wps:.2f} out of bounds"
        prev_end = v["endMs"]

def main():
    root_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    for translation, chapters in LEVEL_2_DATA.items():
        out_dir = os.path.join(root_dir, "assets", "timestamps", translation)
        os.makedirs(out_dir, exist_ok=True)
        for chapter_key, raw_verses in chapters.items():
            verses = build_verses(raw_verses)
            validate_verses(verses, f"{translation}/{chapter_key}")
            out_file = os.path.join(out_dir, f"{chapter_key}.json")
            with open(out_file, "w", encoding="utf-8") as f:
                json.dump(verses, f, indent=2, ensure_ascii=False)
            print(f"✅ Generated {translation}/{chapter_key}.json ({len(verses)} verses)")

if __name__ == "__main__":
    main()
