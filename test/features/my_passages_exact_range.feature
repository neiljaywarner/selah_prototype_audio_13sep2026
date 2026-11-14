# My passages keeps the exact verse range.
# Regenerate: dart run build_runner build --delete-conflicting-outputs
# Run: flutter test test/features/my_passages_exact_range_test.dart

Feature: My passages keeps the exact range
  Bookmarking stores the verse range, not the chapter alone.
  Opening that bookmark returns to the same range.
  Playback uses the narrator. Read-aloud does not start on its own.

  Scenario: A saved range stays exact and reopens on the narrator
    Given the passage playing is {'1 Cor 13:4-7'}
    When I save the passage to My passages
    Then My passages lists {'1 Cor 13:4-7'}
    When I open {'1 Cor 13:4-7'} from My passages
    Then I see the passage {'1 Cor 13:4-7'}
    And the open range is verses {'4'} through {'7'}
    When I can start playback
    Then read aloud did not start
