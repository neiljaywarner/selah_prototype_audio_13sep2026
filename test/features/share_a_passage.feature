# Issue #240 — share a verse or range.
# Regenerate: dart run build_runner build --delete-conflicting-outputs
# Run: flutter test test/features/share_a_passage_test.dart

Feature: Share a passage
  A listener can send the passage they are hearing, or one they saved in My Passages.
  The link carries the reference, for example 1 Cor 13:4-7, not the copyrighted verse.
  Anyone can open it and listen. They do not need an account.

  Scenario: Sharing the passage that is playing
    Given the passage playing is {'1 Cor 13:4-7'}
    When I share the current passage
    Then the share link contains {'1+Cor+13:4-7'}
    And the share payload contains {'1 Cor 13:4-7'}
    And the share payload does not contain the verse {'Love is patient, love is kind'}

  Scenario: Sharing a passage from My Passages
    Given I have {'1 Cor 13:4-7'} in My Passages
    When I share {'1 Cor 13:4-7'} from My Passages
    Then the share link contains {'1+Cor+13:4-7'}
    And the share payload contains {'1 Cor 13:4-7'}
    And the share payload does not contain the verse {'Love is patient, love is kind'}

  Scenario: A failed share does not say the link is ready
    Given the passage playing is {'1 Cor 13:4-7'}
    And the share sheet will fail
    When I share the current passage
    Then I see a share failure

  Scenario: Opening a shared passage without an account
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=1+Cor+13:4-7'} while signed out
    Then I see the passage {'1 Cor 13:4-7'}
    And I can start playback
    And I am not asked to sign in

  Scenario: A broken share link shows a friendly error
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=NotABook+99:1'} while signed out
    Then I see a friendly passage error
    And the player is not blank
    And saving the passage is unavailable
    And I am not asked to sign in
    When I choose the {'WEB'} translation
    Then I see a friendly passage error
    And saving the passage is unavailable
