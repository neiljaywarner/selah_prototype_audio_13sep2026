# A chapter load overtaken by a newer one must not ask to read aloud.

Feature: A stale audio load stays quiet
  Switching chapters while audio is still loading must not let the older
  load open a read-aloud prompt over the newer chapter.

  Scenario: An older audio load does not ask to read the newer chapter
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    When an older audio load is overtaken by {'1CO'} {13}
    Then I am not asked to read aloud
    And the loaded timestamps start at verse {4}
