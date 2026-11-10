# Receive John 16:32-33 in ESV, BSB, and WEB.
# ESV has no live key in this environment, so that scenario uses a scripted
# Crossway client. The queries are still John 16:32 and John 16:33.
# Regenerate: dart run build_runner build
# Run: flutter test test/features/receive_john_16_test.dart

Feature: Receive John 16:32-33
  A shared couple of verses stays on John 16:32-33 in each translation.
  John 16 is not a curated excerpt, so nothing else is substituted.

  Scenario: An old read-aloud answer does not speak the next passage
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    When I play the shared passage
    Then I am asked before the passage is read aloud
    When I load the featured passage {'1 Cor 13:4'} while the question is open
    And I confirm read aloud
    Then the on-screen text includes {'Love is patient'}
    And I do not see the curated wording {'Look, an hour is coming'}
    And read aloud was not confirmed

  Scenario: BSB reads John 16:32-33 aloud
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    Then I see the passage {'John 16:32-33'}
    When I play the shared passage
    Then I am asked before the passage is read aloud
    And the on-screen text includes {'Ask for verse timing'}
    And I do not see the curated wording {'Request from devs'}
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
    And the human narrator chip is hidden
    When I decline read aloud
    Then the passage is not read aloud
    And the human narrator chip is shown
    And the heading stays {'John 16:32-33'}
    And the on-screen text includes {'Look, an hour is coming'}

  Scenario: Declining read aloud keeps the narrator notice
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    When I play the shared passage
    Then I am asked before the passage is read aloud
    And the on-screen text includes {'Narrator stream unavailable'}
    When I decline read aloud
    Then the passage is not read aloud
    And the on-screen text includes {'Narrator stream unavailable'}
    And I do not see the curated wording {'Verse timing for'}

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

  Scenario: An older ESV search does not replace a newer one
    Given the passage playing is {'Psalm 62:5-7'} in {'ESV'}
    And the next ESV lookup is held
    When I search for {'John 16:32-33'}
    And I search for {'John 3:16'}
    And ESV lookups continue
    Then the heading stays {'John 3:16'}
    And the on-screen text includes {'Fixture text for John three verse sixteen only'}
    And I do not see the curated wording {'verse thirty-two only'}

  Scenario: An ESV search drops an earlier read-aloud yes
    Given the passage playing is {'Psalm 62:5-7'} in {'ESV'}
    When I confirm the current read aloud
    And the next ESV lookup is held
    And I search for {'John 3:16'}
    Then read aloud was not confirmed

  Scenario: A missing passage is not read from the placeholder
    Given the passage playing is {'Psalm 62:5-7'} in {'WEB'}
    When I play the shared passage
    Then the placeholder is not spoken
    And the on-screen text includes {'The words for this passage are not loaded'}
    And the heading stays {'Psalm 62:5-7'}

  Scenario: A confirmed read-aloud does not speak the passage that replaced it
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    When I play the shared passage
    Then I am asked before the passage is read aloud
    When playback stops are held
    And I confirm read aloud
    And I load the featured passage {'1 Cor 13:4'}
    And playback stops continue
    Then read aloud was not confirmed
