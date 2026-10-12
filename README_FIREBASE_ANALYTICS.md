# Firebase & Google Analytics Architecture: Selah Word

This guide details the real-time telemetry architecture, event dispatch pipelines, and verification procedures for **Selah Scripture Audio Meditation** across Web and Android.

---

## 🎯 Architecture Summary

| Platform | Primary Transport | Identifier | Verification Mode |
| :--- | :--- | :--- | :--- |
| **Web** (`selahword.web.app`) | Headless `gtag.js` bridge via `dart:js_interop` | Measurement ID: `G-7LFS54TTFM` | GA4 Realtime / DebugView |
| **Android** (Google Pixel 9a) | Native Firebase SDK + ADB logging (`FA`/`FA-SVC`) | Package: `com.example.selah_prototype_audio_13sep2026` | `adb shell setprop` + DebugView |
| **iOS** (Simulator / Devices) | Deferred to [#86](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/86) & [#87](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/87) | Bundle ID: `com.example.selahPrototypeAudio13sep2026` | TestFlight Beta / Scheme args |

---

## 🌐 Web: Why `web_gtag_helper_web.dart` is Used

### The Headless Web Gtag Bridge Pattern
In modern Flutter Web (Dart 3.x+), telemetry is routed through `lib/src/core/analytics/web_gtag_helper_web.dart`:

```dart
@JS('gtag')
external void _gtag(JSString command, JSString action, [JSAny? params]);
```

### Why This Is Preferred for Web
1. **Zero Bundle Bloat**: Eliminates the overhead of importing multiple large FlutterFire JS wrappers (`firebase_core_web`, `firebase_analytics_web`).
2. **Standard Google Analytics 4 (GA4) Ingestion**: Firebase Analytics on the web compiles down to GA4 (`G-7LFS54TTFM`). Dispatches to `window.gtag` feed directly into the Firebase Analytics console with 100% data parity.
3. **No Compilation or Dependency Friction**: Compiles cleanly with both `dart2js` and `dart2wasm` without plugin version lock-ins.
4. **Conditional Stub Isolation**: Completely decoupled from mobile targets via `web_gtag_helper.dart` conditional export—zero runtime impact on Android/iOS.

---

## ⏱️ When to Expect Telemetry in Firebase Console

### 1. Web Realtime View (`Firebase Console -> Analytics -> Realtime` or `Google Analytics -> Reports -> Realtime`)
* **When to check**: **15 to 30 seconds** after interacting with `https://selahword.web.app`.
* **What you see**:
  * Users in last 30 minutes.
  * Active page title and location (`/`).
  * Custom event count cards (`select_knob_value`, `play_chapter`, `change_setting`).

### 2. Web DebugView (`Firebase Console -> Analytics -> DebugView`)
* **When to check**: **1 to 5 seconds** after user interaction!
* **How to enable**:
  * **Option A**: Run in debug mode (`flutter run -d chrome`). The app automatically injects `'debug_mode': true` into the event payload.
  * **Option B**: Install the [Google Analytics Debugger](https://chromewebstore.google.com/detail/google-analytics-debugger/jnnbpmfnfgllkg commissioner) Chrome extension and turn it ON.
  * **Option C**: Append `?debug_mode=true` to your URL when browsing `https://selahword.web.app`.

### 3. Android Realtime & DebugView
* **When to check**: **2 to 5 seconds** after action on device.
* **How to enable Android Debug Mode**:
  Run via ADB:
  ```bash
  adb shell setprop debug.firebase.analytics.app com.example.selah_prototype_audio_13sep2026
  adb shell setprop log.tag.FA VERBOSE
  adb shell setprop log.tag.FA-SVC VERBOSE
  ```
* **Verify locally in terminal**:
  ```bash
  adb logcat -v time -s FA FA-SVC flutter
  ```
  You will see:
  ```text
  🔥 [FIREBASE EVENT]: select_knob_value => {knob: repetitions, selected_value: 7}
  ```

---

## 📊 Core Events Logged across Platforms

| Event Name | Key Parameters | User Action Trigger |
| :--- | :--- | :--- |
| `select_knob_value` | `knob: 'repetitions'`, `selected_value: 7`, `knob_variant_group` | Tapping repetition count knob |
| `play_chapter` | `book: 'JHN'`, `chapter: 1`, `translation: 'BSB'`, `audio_mode` | Starting audio playback |
| `play_tts` | `chapter: '1 Corinthians 13:4-7'`, `translation: 'WEB'` | Playing Text-to-Speech audio |
| `change_setting` | `setting: 'repetitions'`, `value: 7` | Updating repetition or pause gap |
| `change_translation` | `translation: 'WEB'` | Switching between BSB / WEB / NIV |
| `feedback_submitted` | `rating: 'happy'`, `feedback_type`, `has_comment` | Submitting 3-face feedback |
| `feature_vote_toggled` | `feature_id: 'walking_mode'`, `voted: true` | Voting on roadmap items |

---

## 🛠️ Verification Checklist

- [x] Web app registered in `selahwordapp` (`Measurement ID: G-7LFS54TTFM`).
- [x] Google tag script configured in `web/index.html`.
- [x] `web_gtag_helper_web.dart` dispatching via `dart:js_interop`.
- [x] Android device property set: `debug.firebase.analytics.app`.
- [x] Logcat verified real-time event logging on Pixel 9a.
- [x] iOS deferred to GitHub Issues [#86](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/86), [#87](https://github.com/neiljaywarner/selah_prototype_audio_13sep2026/issues/87).
