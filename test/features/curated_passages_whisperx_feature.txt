Feature: Curated WhisperX Passage Audio Excerpts and Guardrails
  As a scripture meditator
  I want to listen to curated scripture excerpts (e.g., 1 Cor 13:4-7, Matt 11:28-30, Rom 8:31-39, Psalm 23)
  with precision WhisperX word-aligned timestamps and continuous meditation looping
  And receive clear guidance when requesting an unaligned custom verse range

  Background:
    Given the Selah meditation app is running
    And the user is on the Chapter Player Screen
    And the curated excerpts catalog contains "1 Cor 13:4–7", "Matt 11:28–30", "Rom 8:31–39", and "Psalm 23"

  Scenario: Display curated passage chips in the horizontal presets bar
    Then the horizontal presets bar displays chip "1 Cor 13:4–7"
    And the horizontal presets bar displays chip "Matt 11:28–30"
    And the horizontal presets bar displays chip "Rom 8:31–39"
    And the horizontal presets bar displays chip "Psalm 23"

  Scenario: Selecting 1 Cor 13:4-7 loads excerpt text and clips narrator audio
    When the user taps the chip "1 Cor 13:4–7"
    Then the player title displays "1 Cor 13:4–7"
    And the text preview contains "Love is patient, love is kind"
    And the text preview does not contain "If I speak in the tongues of men or of angels"
    And the audio stream is clipped to verses 4 through 7 using WhisperX timestamps
    And the narration mode indicates "🎙️ Human Narrator"

  Scenario: Selecting Matthew 11:28-30 excerpt
    When the user taps the chip "Matt 11:28–30"
    Then the player title displays "Matt 11:28–30"
    And the text preview contains "Come to Me, all you who are weary and burdened"
    And the audio stream is clipped to verses 28 through 30

  Scenario: Selecting Romans 8:31-39 excerpt
    When the user taps the chip "Rom 8:31–39"
    Then the player title displays "Rom 8:31–39"
    And the text preview contains "If God is for us, who can be against us?"
    And the audio stream is clipped to verses 31 through 39

  Scenario: Selecting Psalm 23 excerpt
    When the user taps the chip "Psalm 23"
    Then the player title displays "Psalm 23"
    And the text preview contains "The LORD is my shepherd; I shall not want"
    And the audio stream is clipped to verses 1 through 6

  Scenario: Meditation loop cycle retains excerpt window
    Given audio for "1 Cor 13:4–7" is playing
    And loop mode is configured for 3 iterations
    When playback reaches the end of verse 7
    Then playback seamlessly rewinds to the start of verse 4 (not the beginning of chapter 13)
    And the iteration counter increments to "Loop 2 of 3"

  Scenario: Translation switching preserves excerpt boundaries
    Given "Rom 8:31–39" is loaded in Berean Standard Bible (BSB)
    When the user switches translation to World English Bible (WEB)
    Then the player loads the WEB WhisperX timestamps for ROM 8
    And the excerpt window remains clipped to verses 31 through 39

  Scenario: Custom uncurated verse range search displays Coming Soon snackbar
    When the user enters "col 1:17-20" in the reference search box
    And taps the Play button
    Then a floating SnackBar appears with message:
      "Feature coming soon: Whole-chapter audio available; verse-range alignment for this passage is coming soon!"
    And the player does not attempt an invalid multi-verse chapter request

  Scenario: Single verse or whole chapter search functions normally
    When the user enters "John 1" or "Colossians 1" in the reference search box
    And taps the Play button
    Then the player routes to the full chapter audio for the requested reference
