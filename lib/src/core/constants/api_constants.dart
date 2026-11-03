const String kApiBibleBaseUrl = 'https://rest.api.bible/v1';

// Default values redacted for public repository safety
const String kApiBibleKey = String.fromEnvironment('API_BIBLE_KEY', defaultValue: 'REDACTED');
const String kAptabaseAppKey = String.fromEnvironment('APTABASE_KEY', defaultValue: 'REDACTED');
const String kPostHogApiKey = String.fromEnvironment(
  'POSTHOG_KEY',
  defaultValue: String.fromEnvironment('POSTHOG_MEMVERSE_API_KEY', defaultValue: 'REDACTED'),
);
const String kPostHogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);

// Audio and Text Bible IDs on API.Bible
// BSB Audio: Berean Standard Audio Bible (Non-drama, 66 books OT + NT)
const String kBsbAudioBibleId = 'aadc8a2f4bdb467b-01';
// WEB Audio: World English Bible (Drama NT, 27 books NT)
const String kWebAudioBibleId = '105a06b6146d11e7-01';
// Legacy/Default fallback ID
const String kDefaultAudioBibleId = kBsbAudioBibleId;

const String kBsbTextBibleId = 'bba9f40183526463-01';
const String kWebTextBibleId = '9879dbb7cfe39e4d-01';

// Crossway ESV API v3 (https://api.esv.org/docs/).
// Inject at build time with --dart-define=ESV_API_KEY=...
// Never commit a real key. The default sentinel matches the other keys.
const String kEsvBaseUrl = 'https://api.esv.org/v3';
const String kEsvApiKey = String.fromEnvironment('ESV_API_KEY', defaultValue: 'REDACTED');

/// Strips surrounding whitespace and accidental shell quotes (`'...'` or `"..."`)
/// from `--dart-define` values, returning `''` when unset or `REDACTED`.
String sanitizeEnvSecret(String raw) {
  var cleaned = raw.trim();
  while (cleaned.length >= 2 &&
      ((cleaned.startsWith("'") && cleaned.endsWith("'")) ||
          (cleaned.startsWith('"') && cleaned.endsWith('"')))) {
    cleaned = cleaned.substring(1, cleaned.length - 1).trim();
  }
  if (cleaned.isEmpty || cleaned.toUpperCase() == 'REDACTED') {
    return '';
  }
  return cleaned;
}

String get sanitizedEsvApiKey => sanitizeEnvSecret(kEsvApiKey);
String get sanitizedApiBibleKey => sanitizeEnvSecret(kApiBibleKey);

/// Short mark Crossway requires next to quoted ESV text.
const String kEsvShortCopyright = '(ESV)';

/// Shown in the player notice when ESV text is on screen. Not spoken aloud.
const String kEsvCopyrightNotice =
    'Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard Version®), '
    'copyright © 2001 by Crossway, a publishing ministry of Good News Publishers. '
    'Used by permission. All rights reserved.';

/// One HTTP call per verse, but stop expanding before the 60 requests/minute cap.
/// Crossway also allows at most 500 verses per request, 1,000 requests/hour,
/// and 5,000 requests/day.
const int kEsvMaxSingleVerseLookups = 60;
