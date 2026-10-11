# Feature Spec: Walking, Driving & Background Meditation Mode

## 🎯 Problem Statement
When meditating on Scripture while walking, driving (via Bluetooth/CarPlay), or with the phone screen locked in a pocket, users expect continuous Scripture audio and repetition loops without interruption. 

Currently, when the mobile operating system backgrounds the application, background execution limits can suspend the audio loop or stop playback. Additionally, users lack system lockscreen controls to see the current chapter or pause/play.

---

## 💡 Solution Overview
Integrate a persistent OS-level Media Service using [`just_audio_background`](https://pub.dev/packages/just_audio_background) and [`audio_service`](https://pub.dev/packages/audio_service) across iOS and Android:

1. **System Media Controls (Lockscreen & Notification Shade)**:
   * **Title:** Book & Chapter (e.g., *"1 Corinthians 13"* or *"Psalms 23"*).
   * **Artist / Narrator:** Translation details (e.g., *"Berean Standard Bible • Barry Hays"* or *"World English Bible • Drama NT"*).
   * **Album Artwork:** Embedded Selah app icon (Latin cross with golden open Bible).
   * **Interactive Actions:** Play/Pause, Loop Count indicator, and Restart Chapter.
2. **Infinite Background Looping**:
   * Automatic gap-managed repetition continues seamlessly even when screen is locked or another app (such as Maps or Health) is active.
3. **Hardware / Bluetooth Integration**:
   * Responds to headphone button clicks, car steering wheel media controls, and Bluetooth disconnects (auto-pause on disconnect).
4. **Dynamic Island & Live Activities (iOS)**:
   * Displays the active Scripture reference and meditation iteration count in the Dynamic Island on supported iPhones.

---

## 🛠️ Implementation Plan

### 1. Platform Permissions & Configuration
* **Android (`android/app/src/main/AndroidManifest.xml`)**:
  ```xml
  <uses-permission android:name="android.permission.WAKE_LOCK" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
  
  <service android:name="com.ryanheise.audioservice.AudioService"
      android:foregroundServiceType="mediaPlayback"
      android:exported="true" tools:ignore="ExportedService">
    <intent-filter>
      <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
  </service>
  ```
* **iOS (`ios/Runner/Info.plist`)**:
  ```xml
  <key>UIBackgroundModes</key>
  <array>
    <string>audio</string>
    <string>fetch</string>
  </array>
  ```

### 2. Audio Source Tagging (`AudioSource.uri`)
Wrap streaming URIs with `MediaItem` metadata:
```dart
AudioSource.uri(
  Uri.parse(streamUrl),
  tag: MediaItem(
    id: '${chapter.bookCode}_${chapter.chapterNumber}',
    album: 'Selah Scripture Meditation',
    title: chapter.reference,
    artist: translation.name,
    artUri: Uri.parse('asset:///assets/selah_logo.png'),
  ),
);
```

### 3. Background Loop Resilience
Configure `AudioPlayer.setLoopMode(LoopMode.one)` or leverage `ConcatenatingAudioSource` so chapter replay events trigger at the native OS audio player layer rather than waiting for Dart UI lifecycle timers.

---

## 🔗 Related Tracking
* **GitHub Issue:** [#6](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/6) (Walking / Driving Background Audio Mode & Rich OS Lockscreen Media Controls)
