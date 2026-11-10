# An older chapter load must not replace the timestamps of a newer one.

Feature: Chapter timestamps stay with the current load
  Overlapping chapter loads share one timestamp field. The load that
  finishes last must not keep its timestamps when a newer load already won.

  Scenario: An older chapter load keeps the newer timestamps
    Given I open the share link {'https://neiljaywarner.github.io/selah_prototype_audio_13sep2026/?ref=John+16:32-33'} in {'BSB'} while signed out
    When the next timestamp load is held
    And I load the bundled chapter {'PSA'} {62}
    And I load the bundled chapter {'1CO'} {13}
    And timestamp loads continue
    Then the loaded timestamps start at verse {4}
