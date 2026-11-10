# Issue #245 — an installed Android app opens the shared https link.
# Regenerate: dart run build_runner build --delete-conflicting-outputs
# Run: flutter test test/features/android_app_link_test.dart

Feature: Open an Android App Link
  Tapping https://selahword.web.app/?ref=... opens Selah on that passage.
  The listener stays signed out. A bad reference shows the existing friendly error.
  Opening a link does not start read-aloud on its own.

  Scenario: A cold start opens the shared passage
    Given the app opens from the Android link {'https://selahword.web.app/?ref=1+Cor+13:4-7'}
    Then I see the passage {'1 Cor 13:4-7'}
    And I am not asked to sign in
    And I am not asked to read aloud
    And read aloud did not start

  Scenario: A link while the app is open switches the passage
    Given the app is open signed out
    When an Android link arrives {'https://selahword.web.app/?ref=Psalm+62:5-7'}
    Then I see the passage {'Psalm 62:5-7'}
    And I am not asked to sign in
    And I am not asked to read aloud
    And read aloud did not start

  Scenario: A bad Android link shows a friendly error
    Given the app opens from the Android link {'https://selahword.web.app/?ref=NotABook+99:1'}
    Then I see a friendly passage error
    And playback is unavailable
    And I am not asked to read aloud
    And read aloud did not start
