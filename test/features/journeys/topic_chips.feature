Feature: Topic chips

  Scenario: Choosing Peace shows a peace passage
    Given the topic bar is showing Featured
    When I choose the topic "Peace"
    Then I see the passage chip "Philippians 4"
    And I see the passage chip "John 14"
