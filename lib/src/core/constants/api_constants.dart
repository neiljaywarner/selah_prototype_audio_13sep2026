const String kApiBibleBaseUrl = 'https://rest.api.bible/v1';

// Default values redacted for public repository safety
const String kApiBibleKey = String.fromEnvironment('API_BIBLE_KEY', defaultValue: 'REDACTED');
const String kAptabaseAppKey = String.fromEnvironment('APTABASE_KEY', defaultValue: 'REDACTED');

// Audio and Text Bible IDs on API.Bible
// BSB Audio: Berean Standard Audio Bible (Non-drama, 66 books OT + NT)
const String kBsbAudioBibleId = 'aadc8a2f4bdb467b-01';
// WEB Audio: World English Bible (Drama NT, 27 books NT)
const String kWebAudioBibleId = '105a06b6146d11e7-01';
// Legacy/Default fallback ID
const String kDefaultAudioBibleId = kBsbAudioBibleId;

const String kBsbTextBibleId = 'bba9f40183526463-01';
const String kWebTextBibleId = '9879dbb7cfe39e4d-01';
