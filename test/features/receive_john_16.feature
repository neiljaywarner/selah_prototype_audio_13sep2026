# Receive John 16:32-33 in ESV, BSB, and WEB.
# ESV has no live key in this environment, so that scenario uses a scripted
# Crossway client. The queries are still John 16:32 and John 16:33.
# Regenerate: dart run build_runner build
# Run: flutter test test/features/receive_john_16_test.dart

Feature: Receive John 16:32-33
  A shared couple of verses stays on John 16:32-33 in each translation.
  John 16 is not a curated excerpt, so nothing else is substituted.

  Scenario: BSB reads John 16:32-33 aloud
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    Then I see the passage {'John 16:32-33'}
    When I play the shared passage
    Then I am asked before the passage is read aloud
    And text to speech has not started
    And the on-screen text includes {'Look, an hour is coming'}
    And the on-screen text includes {'take courage'}
    And I do not see the curated wording {'For God so loved the world'}
    And I do not see the curated wording {'In the beginning was the Word'}
    And the heading stays {'John 16:32-33'}
    When I confirm read aloud
    Then the passage is read aloud
    And the attribution includes {'Barry Hays'}
    And I see verse timing marked unaligned

  Scenario: WEB reads John 16:32-33 aloud
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    When I choose the {'WEB'} translation
    Then I am asked before the passage is read aloud
    And text to speech has not started
    And the on-screen text includes {'Behold, the time is coming'}
    And the on-screen text includes {'cheer up'}
    And I do not see the curated wording {'Look, an hour is coming'}
    And I do not see the curated wording {'For God so loved the world'}
    And the heading stays {'John 16:32-33'}
    When I confirm read aloud
    Then the passage is read aloud
    And the attribution includes {'Hosanna'}
    And I see verse timing marked unaligned

  Scenario: Declining the read aloud leaves John 16 quiet
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    When I play the shared passage
    Then I am asked before the passage is read aloud
    When I decline read aloud
    Then the passage is not read aloud
    And the heading stays {'John 16:32-33'}
    And the on-screen text includes {'Look, an hour is coming'}

  Scenario: ESV requests John 16:32 and John 16:33
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'ESV'} while signed out
    Then I see the passage {'John 16:32-33'}
    When I play the shared passage
    Then the ESV passage requests include {'John 16:32'}
    And the ESV passage requests include {'John 16:33'}
    And the ESV passage requests do not include {'John 3:16'}
    And the on-screen text includes {'verse thirty-two only'}
    And the on-screen text includes {'verse thirty-three only'}
    And the heading stays on {'John 16:32-33'}
    And the attribution includes {'Crossway'}
    And I do not see verse timing marked unaligned

  Scenario: An ESV search replaces the previous range
    Given the passage playing is {'Psalm 62:5-7'} in {'ESV'}
    When I search for {'John 16:32-33'}
    And I turn on API.Bible narrator translations
    And I choose the {'BSB'} translation
    Then the heading stays {'John 16:32-33'}
    And the on-screen text includes {'Look, an hour is coming'}
    And I do not see the curated wording {'Rest in God alone'}

  Scenario: A later translation wins over a slow ESV search
    Given the passage playing is {'Psalm 62:5-7'} in {'ESV'}
    And ESV lookups are held
    When I search for {'John 16:32-33'}
    And I turn on API.Bible narrator translations
    And I choose the {'BSB'} translation
    And ESV lookups continue
    Then the heading stays {'Psalm 62:5-7'}
    And the on-screen text includes {'Rest in God alone'}
    And I do not see the curated wording {'verse thirty-two only'}
