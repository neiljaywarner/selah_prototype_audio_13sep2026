# Issue #273 — a passage chip loads the passage and does not start audio.
# Related: #261 quiet open / no autoplay.
# Regenerate: dart run build_runner build --delete-conflicting-outputs
# Run: flutter test test/features/passage_chip_playback_test.dart

Feature: A passage chip loads without starting playback
  Tapping a passage chip loads that passage and waits.
  Narrator audio and text to speech start only from the play control.

  Scenario: Tapping Matt loads it and stays paused until play
    Given the app is open signed out
    When I tap the passage chip {'Matt 11:28–30'}
    Then the heading stays {'Matt 11:28–30'}
    And the passage chip {'Matt 11:28–30'} is selected
    And the passage chip {'1 Cor 13:4–7'} is not selected
    And playback has not started
    When I tap the play control
    Then playback has started
    And read aloud did not start
