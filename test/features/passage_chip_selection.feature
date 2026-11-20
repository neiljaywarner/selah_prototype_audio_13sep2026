# Issue #271 — a ?ref= link selects only the matching passage chip.
# Regenerate: dart run build_runner build --delete-conflicting-outputs
# Run: flutter test test/features/passage_chip_selection_test.dart

Feature: Passage chip selection follows the loaded reference
  Opening a link selects the one chip that names that passage.
  A different reference leaves the curated 1 Cor 13:4-7 chip unselected.
  The chip label uses an en dash. Links use a hyphen. Both are the same passage.

  Scenario: A John link does not leave 1 Cor selected
    Given I open the share link {'https://selahword.web.app/?ref=John+3:16-18'} while signed out
    Then I see the passage {'John 3:16-18'}
    And the passage chip {'1 Cor 13:4–7'} is not selected
    And the passage chip {'Matt 11:28–30'} is not selected
    And the passage chip {'Rom 8:31–39'} is not selected
    And the passage chip {'Psalm 23'} is not selected

  Scenario: The matching curated chip is selected from a hyphenated link
    Given I open the share link {'https://selahword.web.app/?ref=1+Cor+13:4-7'} while signed out
    Then I see the passage {'1 Cor 13:4-7'}
    And the passage chip {'1 Cor 13:4–7'} is selected
    And the passage chip {'Matt 11:28–30'} is not selected
    And the passage chip {'Psalm 23'} is not selected

  Scenario: A different range on the same chapter does not select the curated chip
    Given I open the share link {'https://selahword.web.app/?ref=1+Cor+13:8-13'} while signed out
    Then I see the passage {'1 Cor 13:8-13'}
    And the passage chip {'1 Cor 13:4–7'} is not selected
    And the passage chip {'Matt 11:28–30'} is not selected
