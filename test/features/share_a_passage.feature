# Issue #240 share a verse or range. Issue #246 includes the loaded words.
# Regenerate: dart run build_runner build --delete-conflicting-outputs
# Run: flutter test test/features/share_a_passage_test.dart

Feature: Share a passage
  A listener can send the passage they are hearing, or one they saved in My Passages.
  The message includes the words already on screen, the reference, that translation's
  attribution, and the link. A long ESV range, or a passage whose words are not
  loaded, still shares the reference and the link. Anyone can open the link and
  listen. They do not need an account.

  Scenario: Sharing the passage that is playing
    Given the passage playing is {'1 Cor 13:4-7'}
    When I share the current passage
    Then the share link contains {'https://selahword.web.app/?ref=1+Cor+13:4-7'}
    And the share payload contains {'1 Cor 13:4-7'}
    And the share payload contains the verse {'Love is patient, love is kind'}
    And the share message contains {'(BSB)'}
    And the share message contains {'Public Domain · Narrator: Barry Hays'}
    And the share message does not contain {'Crossway'}
    And read aloud did not start

  Scenario: Sharing a passage from My Passages
    Given I have {'1 Cor 13:4-7'} in My Passages
    When I share {'1 Cor 13:4-7'} from My Passages
    Then the share link contains {'https://selahword.web.app/?ref=1+Cor+13:4-7'}
    And the share payload contains {'1 Cor 13:4-7'}
    And the share payload contains the verse {'Love is patient, love is kind'}
    And the share message contains {'(BSB)'}
    And read aloud did not start

  Scenario: Sharing loaded ESV words
    Given the passage playing is {'John 16:32-33'} in {'ESV'}
    When I play the shared passage
    And I share the current passage
    Then the share link contains {'https://selahword.web.app/?ref=John+16:32-33'}
    And the share payload contains {'John 16:32-33'}
    And the share payload contains the verse {'verse thirty-two only'}
    And the share payload contains the verse {'verse thirty-three only'}
    And the share message contains {'(ESV)'}
    And the share message contains {'Crossway'}
    And read aloud did not start

  Scenario: A long ESV range shares the reference without the verse
    Given the passage playing is {'2 John 1:1-13'} in {'ESV'}
    And ESV lookups return {'Placeholder line only.'}
    When I play the shared passage
    Then the on-screen text includes {'Placeholder line only.'}
    When I share the current passage
    Then the share link contains {'https://selahword.web.app/?ref=2+John+1:1-13'}
    And the share payload contains {'2 John 1:1-13'}
    And the share payload does not contain the verse {'Placeholder line only.'}
    And the share message contains {'2 John 1:1-13'}
    And read aloud did not start

  Scenario: Sharing when the words are not loaded
    Given the passage playing is {'John 3:16'}
    When I share the current passage
    Then the share link contains {'https://selahword.web.app/?ref=John+3:16'}
    And the share payload contains {'John 3:16'}
    And the share payload does not contain the verse {'Press play to listen'}
    And read aloud did not start

  Scenario: Sharing a saved passage that is not on screen
    Given I have {'John 3:16'} in My Passages
    When I share {'John 3:16'} from My Passages
    Then the share link contains {'https://selahword.web.app/?ref=John+3:16'}
    And the share payload contains {'John 3:16'}
    And the share payload does not contain the verse {'Love is patient, love is kind'}
    And read aloud did not start

  Scenario: NIV shares do not paste the verse
    Given the passage playing is {'1 Cor 13:4-7'} in {'NIV'}
    When I share the current passage
    Then the share link contains {'https://selahword.web.app/?ref=1+Cor+13:4-7'}
    And the share payload contains {'1 Cor 13:4-7'}
    And the share payload does not contain the verse {'Love is patient, love is kind'}
    And the share message contains {'NIV'}
    And read aloud did not start

  Scenario: ESV does not share another translation's words
    Given the passage playing is {'1 Cor 13:4-7'} in {'ESV'}
    When I share the current passage
    Then the share link contains {'https://selahword.web.app/?ref=1+Cor+13:4-7'}
    And the share payload contains {'1 Cor 13:4-7'}
    And the share payload does not contain the verse {'Love is patient, love is kind'}
    And read aloud did not start

  Scenario: A failed share does not say the link is ready
    Given the passage playing is {'1 Cor 13:4-7'}
    And the share sheet will fail
    When I share the current passage
    Then I see a share failure

  Scenario: Opening a shared passage without an account
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=1+Cor+13:4-7'} while signed out
    Then I see the passage {'1 Cor 13:4-7'}
    And I can start playback
    And listening session chrome is shown
    And I am not asked to sign in

  Scenario: A broken share link shows a friendly error
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=NotABook+99:1'} while signed out
    Then I see a friendly passage error
    And the player is not blank
    And saving the passage is unavailable
    And playback is unavailable
    And listening session chrome is hidden
    And I am not asked to sign in
    When I choose the {'WEB'} translation
    Then I see a friendly passage error
    And saving the passage is unavailable
    And listening session chrome is hidden

  Scenario: A broken ESV link hides listening chrome
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=NotABook+99:1'} in {'ESV'} while signed out
    Then I see a friendly passage error
    And listening session chrome is hidden
