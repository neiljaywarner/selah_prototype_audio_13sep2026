# Journeys a listener can see without an ESV key, a network, or an account.
# Hand-maintained alongside quiet_player_test.dart (build_runner is not on this branch).

Feature: Listening without an ESV key

  Scenario: The player opens on the featured passage and does not speak
    Given the player is open without an ESV key
    Then I see the Selah header
    And I see the passage text "Love is patient, love is kind"
    And speech has not started
    And I am not asked to sign in

  Scenario: An unknown reference does not replace the passage or start speech
    Given the player is open without an ESV key
    When I search for "NotABook 99"
    Then I see that the reference was rejected
    And I see the passage text "Love is patient, love is kind"
    And speech has not started

  Scenario: Settings lists the translations available without a key
    Given the player is open without an ESV key
    When I open meditation settings
    Then I see "Meditation Settings"
    And I see "BIBLE TRANSLATION"
    And I see "BSB"
    And I see "WEB"
