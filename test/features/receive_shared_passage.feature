# Issue #249 — a shared range must not play a different curated excerpt.
# Regenerate: dart run build_runner build --delete-conflicting-outputs
# Run: flutter test test/features/receive_shared_passage_test.dart

Feature: Receive a shared passage on BSB
  Opening a link while signed out, with no ESV key, shows the shared range.
  A chapter that already has a different curated excerpt does not replace the share.
  When that other excerpt is the only bundled recording, Selah asks before
  reading the words aloud and does not play the other excerpt.

  Scenario: Psalm 62:5-7 does not show the curated 62:1-2 text
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=Psalm+62:5-7'} while signed out
    Then I see the passage {'Psalm 62:5-7'}
    And I do not see the curated wording {'My soul finds rest in God alone'}
    When I play the shared passage
    Then I am asked before the passage is read aloud
    And text to speech has not started
    And the on-screen text is the shared BSB range {'Rest in God alone, O my soul'}
    And I do not see the curated wording {'My soul finds rest in God alone'}
    And I do not see the curated wording {'I will never be shaken'}
    And the heading stays {'Psalm 62:5-7'}
    And playback is the shared range and not the full chapter
    When I decline read aloud
    Then the passage is not read aloud
    When I choose the {'WEB'} translation
    Then the heading stays {'Psalm 62:5-7'}
    And I do not see the curated wording {'Rest in God alone'}
    And the placeholder is not spoken

  Scenario: A slow passage does not replace a newer one
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    And public domain lookups are held
    When I start playback without waiting
    And I route to {'John 3:16'}
    And public domain lookups continue
    Then the heading stays {'John 3:16'}
    And the on-screen text includes {'Press play to listen to John 3:16'}
    And I do not see the curated wording {'Look, an hour is coming'}

  Scenario: A different range on a curated chapter does not use that excerpt
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=1+Cor+13:8-13'} while signed out
    Then I see the passage {'1 Cor 13:8-13'}
    And I do not see the curated wording {'Love is patient, love is kind'}
    When I play the shared passage
    Then I see the passage {'1 Cor 13:8-13'}
    And I do not see the curated wording {'Love is patient, love is kind'}
    And I do not see the curated wording {'bears all things, believes all things'}
