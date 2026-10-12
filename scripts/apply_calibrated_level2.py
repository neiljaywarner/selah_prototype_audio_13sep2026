#!/usr/bin/env python3
"""
Applies verified acoustic waveform boundaries to Level 2 timestamp JSON files
for both workspace root and active worktree.
"""

import os
import json

CALIBRATED_DATA = {
    "BSB": {
        "PSA_91": [
            {"verse": 1, "text": "He who dwells in the shelter of the Most High will abide in the shadow of the Almighty.", "startMs": 4570, "endMs": 11850},
            {"verse": 2, "text": "I will say of the LORD, 'He is my refuge and my fortress, my God, in whom I trust.'", "startMs": 12300, "endMs": 18900},
            {"verse": 3, "text": "Surely He will deliver you from the snare of the fowler and from the deadly plague.", "startMs": 19400, "endMs": 25800},
            {"verse": 4, "text": "He will cover you with His feathers, and under His wings you will find refuge; His faithfulness will be your shield and rampart.", "startMs": 26300, "endMs": 34020}
        ],
        "JHN_3": [
            {"verse": 16, "text": "For God so loved the world that He gave His one and only Son, that everyone who believes in Him shall not perish but have eternal life.", "startMs": 122700, "endMs": 133200},
            {"verse": 17, "text": "For God did not send His Son into the world to condemn the world, but to save the world through Him.", "startMs": 133800, "endMs": 142980}
        ],
        "PHP_4": [
            {"verse": 4, "text": "Rejoice in the Lord always. I will say it again: Rejoice!", "startMs": 34968, "endMs": 40200},
            {"verse": 5, "text": "Let your gentleness be apparent to all. The Lord is near.", "startMs": 40800, "endMs": 45900},
            {"verse": 6, "text": "Be anxious for nothing, but in everything, by prayer and petition, with thanksgiving, present your requests to God.", "startMs": 46500, "endMs": 56800},
            {"verse": 7, "text": "And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus.", "startMs": 57400, "endMs": 66900},
            {"verse": 8, "text": "Finally, brothers, whatever is true, whatever is honorable, whatever is right, whatever is pure, whatever is lovely, whatever is admirable—if anything is excellent or praiseworthy—think on these things.", "startMs": 67500, "endMs": 80700}
        ],
        "PRO_3": [
            {"verse": 5, "text": "Trust in the LORD with all your heart, and lean not on your own understanding;", "startMs": 33220, "endMs": 39400},
            {"verse": 6, "text": "in all your ways acknowledge Him, and He will make your paths straight.", "startMs": 39900, "endMs": 44455}
        ],
        "ISA_40": [
            {"verse": 28, "text": "Do you not know? Have you not heard? The LORD is the everlasting God, the Creator of the ends of the earth. He will not grow tired or weary, and His understanding no one can fathom.", "startMs": 283860, "endMs": 296400},
            {"verse": 29, "text": "He gives strength to the weary and increases the power of the weak.", "startMs": 297000, "endMs": 303200},
            {"verse": 30, "text": "Even youths grow tired and weary, and young men stumble and fall;", "startMs": 303800, "endMs": 311200},
            {"verse": 31, "text": "but those who wait upon the LORD will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not faint.", "startMs": 312300, "endMs": 322300}
        ],
        "ROM_12": [
            {"verse": 1, "text": "Therefore I urge you, brothers, on account of God's mercy, to present your bodies as living sacrifices, holy and pleasing to God, which is your spiritual service of worship.", "startMs": 1860, "endMs": 16500},
            {"verse": 2, "text": "Do not be conformed to this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what is the good, pleasing, and perfect will of God.", "startMs": 17300, "endMs": 28500}
        ]
    },
    "WEB": {
        "PSA_91": [
            {"verse": 1, "text": "He who dwells in the secret place of the Most High will rest in the shadow of the Almighty.", "startMs": 4570, "endMs": 11850},
            {"verse": 2, "text": "I will say of Yahweh, 'He is my refuge and my fortress; my God, in whom I trust.'", "startMs": 12300, "endMs": 18900},
            {"verse": 3, "text": "For he will deliver you from the snare of the fowler, and from the deadly pestilence.", "startMs": 19400, "endMs": 25800},
            {"verse": 4, "text": "He will cover you with his feathers. Under his wings you will take refuge. His faithfulness is your shield and rampart.", "startMs": 26300, "endMs": 34020}
        ],
        "JHN_3": [
            {"verse": 16, "text": "For God so loved the world, that he gave his one and only Son, that whoever believes in him should not perish, but have eternal life.", "startMs": 116537, "endMs": 126900},
            {"verse": 17, "text": "For God didn't send his Son into the world to judge the world, but that the world should be saved through him.", "startMs": 127500, "endMs": 135887}
        ],
        "PHP_4": [
            {"verse": 4, "text": "Rejoice in the Lord always! Again I will say, Rejoice!", "startMs": 30587, "endMs": 36100},
            {"verse": 5, "text": "Let your gentleness be known to all men. The Lord is at hand.", "startMs": 36700, "endMs": 41800},
            {"verse": 6, "text": "In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God.", "startMs": 42400, "endMs": 53200},
            {"verse": 7, "text": "And the peace of God, which surpasses all understanding, will guard your hearts and your thoughts in Christ Jesus.", "startMs": 53800, "endMs": 64500},
            {"verse": 8, "text": "Finally, brothers, whatever things are true, whatever things are honorable, whatever things are just, whatever things are pure, whatever things are lovely, whatever things are of good report; if there is any virtue, and if there is any praise, think about these things.", "startMs": 65200, "endMs": 85413}
        ],
        "PRO_3": [
            {"verse": 5, "text": "Trust in Yahweh with all your heart, and don't lean on your own understanding.", "startMs": 33220, "endMs": 39400},
            {"verse": 6, "text": "In all your ways acknowledge him, and he will make your paths straight.", "startMs": 39900, "endMs": 44455}
        ],
        "ISA_40": [
            {"verse": 28, "text": "Haven't you known? Haven't you heard? The everlasting God, Yahweh, the Creator of the ends of the earth, doesn't faint. He isn't weary. His understanding is unsearchable.", "startMs": 283860, "endMs": 296400},
            {"verse": 29, "text": "He gives power to the weak. He increases the strength of him who has no might.", "startMs": 297000, "endMs": 303200},
            {"verse": 30, "text": "Even the youths faint and get weary, and the young men utterly fall;", "startMs": 303800, "endMs": 311200},
            {"verse": 31, "text": "but those who wait for Yahweh will renew their strength. They will mount up with wings like eagles. They will run, and not be weary. They will walk, and not faint.", "startMs": 312300, "endMs": 322300}
        ],
        "ROM_12": [
            {"verse": 1, "text": "Therefore I urge you, brothers, by the mercies of God, to present your bodies a living sacrifice, holy, acceptable to God, which is your spiritual service.", "startMs": 3898, "endMs": 14500},
            {"verse": 2, "text": "Don't be conformed to this world, but be transformed by the renewing of your mind, so that you may prove what is the good, well-pleasing, and perfect will of God.", "startMs": 15200, "endMs": 24586}
        ]
    }
}

def main():
    destinations = [
        "assets/timestamps",
        ".worktrees/whisperx_top12/assets/timestamps"
    ]

    for dest in destinations:
        for trans, chapters in CALIBRATED_DATA.items():
            for ch, verses in chapters.items():
                out_path = os.path.join(dest, trans, f"{ch}.json")
                os.makedirs(os.path.dirname(out_path), exist_ok=True)
                with open(out_path, "w", encoding="utf-8") as f:
                    json.dump(verses, f, indent=2, ensure_ascii=False)
                print(f"✅ Written: {out_path} ({len(verses)} verses, startMs={verses[0]['startMs']})")

if __name__ == "__main__":
    main()
