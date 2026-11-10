Feature: Choosing a passage without an ESV key

  The listener can look up a passage, browse the canon, and start the
  bundled narrator. Text-to-speech does not begin on its own.

  Scenario: Typing Jn offers John and Jonah
    Given the player is open without an ESV key
    When I type "Jn"
    Then I see "John 1" and "Jonah 1"
    And speech has not started

  Scenario: Psalm 23 uses the bundled narrator
    Given the player is open without an ESV key
    When I search for "Psalm 23"
    Then the bundled Psalm 23 narrator is ready
    And speech has not started

  Scenario: An unaligned range can be requested
    Given the player is open without an ESV key
    When I search for "revelation 21:1-4"
    And I request the passage from the devs
    Then I see that the devs were notified
    And the featured passage is still on screen
    And speech has not started

  Scenario: Play and pause stay on the narrator
    Given the player is open without an ESV key
    When I tap play
    Then the narrator is playing
    And speech has not started
    When I tap pause
    Then the narrator is paused
    And speech has not started
