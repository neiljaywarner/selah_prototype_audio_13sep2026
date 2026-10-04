# Mobile Deployment Guide: Android (Google Play) & iOS (App Store)

Step-by-step guide to bundle, sign, and release **Selah** on the Apple App Store and Google Play Console.

---

## 1. Prerequisites & Environment Variables

Ensure you have your production environment defines ready:
```bash
--dart-define=API_BIBLE_KEY="YOUR_KEY"
--dart-define=APTABASE_KEY="YOUR_KEY"
--dart-define=USERORIENT_KEY="YOUR_KEY"
--dart-define=DOORBELL_APP_ID="YOUR_APP_ID"
--dart-define=DOORBELL_API_KEY="YOUR_API_KEY"
```

---

## 2. Android Deployment (Google Play)

### A. Keystore & Signing Setup
1. Generate an upload keystore if you don't already have one:
```bash
keytool -genkey -v -keystore ~/selah-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias selah-upload
```
2. Reference the keystore in `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=selah-upload
storeFile=/Users/neil/selah-upload-keystore.jks
```

### B. Build Production App Bundle (AAB)
```bash
flutter build appbundle --release \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### C. Google Play Console Upload
1. Log in to [Google Play Console](https://play.google.com/console).
2. Create or select **Selah: Scripture Audio Meditation**.
3. Go to **Release** > **Internal Testing** (or Production) > **Create new release**.
4. Drag and drop `app-release.aab`.
5. Enter release notes from [`CHANGELOG.md`](CHANGELOG.md) and click **Save & Review**.

---

## 3. iOS Deployment (Apple App Store & TestFlight)

### A. Apple Developer Team & Bundle ID
1. Open `ios/Runner.xcworkspace` in Xcode.
2. In **Signing & Capabilities**:
   - Set **Team** to your Apple Developer account.
   - Bundle Identifier: `com.selahwordapp.audio` (or your chosen bundle id).
   - Ensure **Background Modes** (Audio, AirPlay, and Picture in Picture) is enabled for background audio meditation.

### B. Build iOS Archive (IPA)
```bash
flutter build ipa --release \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```
Output: `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/selah.ipa`

### C. Upload via Xcode Organizer or Transporter
1. Open Xcode > **Window** > **Organizer** > Select Archive > **Distribute App**.
2. Select **App Store Connect** > **Upload**.
3. Once processed, activate in **TestFlight** for internal testing or submit for App Store Review.

---

## 4. Background Audio Configuration Checklist

Both platforms require permissions for audio playback while screen is locked:

### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS (`ios/Runner/Info.plist`):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```
