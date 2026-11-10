Feature: Passage timing feedback

  Scenario: A peaceful rating is acknowledged
    Given the timing bar is showing for "Psalm 23"
    When I mark the audio as peaceful
    Then I see "Saved 🕊️"
    And I see "Thank you! Glad the audio was peaceful."

  Scenario: A problem report offers calibration choices
    Given the timing bar is showing for "Psalm 23"
    When I report a timing problem
    Then I see "Audio & Timing Calibration"
    And I see "Started too early or cut into words"
