Feature: Feature roadmap

  Scenario: The roadmap is readable without an account
    Given the roadmap is open
    Then I see "Feature Roadmap & Feedback"
    And I see "Verse & Word-Level Karaoke Timestamps"
    And I am not asked to sign in

  Scenario: Voting once records the listener's vote
    Given the roadmap is open
    When I vote for "Verse & Word-Level Karaoke Timestamps"
    Then that feature has one vote
