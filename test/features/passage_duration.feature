# Issue #272 — the duration bar must follow the passage on screen.
# Regenerate: dart run build_runner build --delete-conflicting-outputs
# Run: flutter test test/features/passage_duration_test.dart

Feature: Passage duration follows the loaded passage
  After a passage change, the bar shows that passage's length or an unknown
  length. It does not keep the previous clip.

  Scenario: Reopening a saved passage drops the previous clip length
    Given I have {'John 3:16-18'} in My passages
    And the next narrator load reports {'17'} seconds
    When I tap the passage chip {'Matt 11:28–30'}
    Then the duration bar shows {'00:17'}
    When My passages lists {'John 3:16-18'}
    And I open {'John 3:16-18'} from My passages
    Then I see the passage {'John 3:16-18'}
    And the duration bar shows {'00:00'}
    And the passage chip {'Matt 11:28–30'} is not selected
