# Technical Platform Differences: Selah Scripture Audio Meditation

This document details the architectural, runtime, operating system, and hardware differences across all target platforms for **Selah**.

---

## 1. Executive Matrix of Platform Capabilities

| Capability | Android (Flagship Mobile) | iOS (Mobile) | Web (Browser) | Web PWA (Installed) | Desktop (macOS/Win/Linux)* |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Primary Audio Engine** | Google ExoPlayer (Media3) | Apple AVPlayer / AVQueuePlayer | HTML5 `<audio>` / Web Audio API | HTML5 `<audio>` / Web Audio API | Ffmpeg / CoreAudio / MediaFoundation |
| **Audio Clipping Fidelity** | Sub-millisecond (`ClippingMediaSource`) | Millisecond (`CMTimeRange` / `AVPlayerItem`) | Frame-approximate via HTML5 media | Frame-approximate via HTML5 media | Native buffer clipping |
| **Background Audio** | `Android AudioService` & Foreground Service | `AVAudioSessionCategoryPlayback` | Suspended or throttled when tab inactive | Background audio via Media Session API | Runs as long as desktop process is open |
| **Lockscreen Controls** | Android Media Notification + Lockscreen widget | iOS Lock Screen Now Playing Info Center | Media Session API (browser notification) | Media Session API (system lockscreen on Android) | OS Media Keys / Control Center |
| **WhisperX Timestamps** | Offline Bundled JSON (`rootBundle`) | Offline Bundled JSON (`rootBundle`) | Bundled asset via HTTP / IndexedDB | Offline ServiceWorker Cache / IndexedDB | Offline Bundled JSON (`rootBundle`) |
| **Offline Audio Cache** | SQLite / Local App Storage (`app_dir`) | SQLite / App Sandbox Documents | IndexedDB / CacheStorage | ServiceWorker Cache API / IndexedDB | Local filesystem |
| **TTS Engine** | Android Text-to-Speech (`TextToSpeech`) | iOS AVFoundation Speech (`AVSpeechSynthesizer`) | Web Speech API (`SpeechSynthesis`) | Web Speech API (`SpeechSynthesis`) | Native OS TTS engine |
| **Intended Target** | **Primary Target (Release)** | **Primary Target (Release)** | **Secondary (Quick preview)** | **Primary Web Target (Release)** | **Dev / Test Only (No public distro)** |

*\*Note on Desktop (macOS, Windows, Linux): Desktop builds are strictly developer tool targets for fast local debugging, layout tests, and simulator convenience. There are no plans for commercial or consumer desktop app store distribution.*

---

## 2. Audio Pipeline Deep-Dive

### Android (ExoPlayer via `just_audio`)
* **Under the Hood**: Android runs Google ExoPlayer (AndroidX Media3).
* **Clipping Behavior**: Wrapping streams with `ClippingAudioSource` compiles directly into ExoPlayer's native `ClippingMediaSource`. It does not download or re-encode the stream. When `start` is set to `148000ms`, ExoPlayer seeks directly to keyframe zero-offset within the buffer, starting playback cleanly on the exact syllable.
* **Continuous Looping & Reflection Gaps**: When an iteration finishes, `_audioPlayer.seek(Duration.zero)` immediately rewinds to the start of the `ClippingMediaSource` without re-requesting stream metadata.
* **Background Service**: Utilizes `just_audio_background` configured with an Android `Service` declared in `AndroidManifest.xml` with `android:foregroundServiceType="mediaPlayback"`. Notification controls (Play, Pause, Skip, Repeat) remain active with device screen locked.

### iOS (AVPlayer via `just_audio`)
* **Under the Hood**: Apple's `AVPlayer` and `AVPlayerItem`.
* **Clipping Behavior**: Utilizes `AVPlayerItem` seek boundaries. Requires proper handling of `forwardPlaybackEndTime` and initial seek to `window.start`.
* **Background Mode**: Requires `UIBackgroundModes` containing `audio` in `Info.plist`. The app configures `AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)`.
* **Lockscreen Integration**: Configures `MPNowPlayingInfoCenter` and responds to `MPRemoteCommandCenter` events.

### Web & Progressive Web App (PWA)
* **Under the Hood**: Managed by `just_audio_web`, which wraps the browser HTML5 `<audio>` element.
* **Clipping Nuances**: Browsers do not possess native `ClippingMediaSource`. In standard web, calling `setClip` on an active audio element can fail or require explicit `seek()`. Using `ClippingAudioSource` provides programmatic boundary management, but browser audio thread suspension and autoplay policies apply:
  * **Autoplay Restrictions**: Audio cannot begin playing automatically until the user has performed a physical interaction (tap/click) in the browser context.
  * **Audio Element Gaps**: Transitioning between repetitions in web browsers may introduce slight 50–100ms hardware buffer re-initialization latencies compared to ExoPlayer.
* **PWA Enhancements**:
  * When installed via browser prompt ("Add to Home Screen"), the PWA runs in `standalone` display mode without browser URL bars.
  * Service Workers cache the WhisperX JSON timestamp bundles and UI assets, enabling immediate offline launch.
  * Web Media Session API (`navigator.mediaSession`) routes title, artwork, and play/pause controls to the host system notification tray.

### Desktop Targets (macOS, Windows, Linux)
* **Role**: Exclusively used for fast Flutter hot reload, developer unit/widget tests, and Marionette/Driver sanity runs.
* **Gotchas**:
  * **macOS Sandbox**: macOS App Sandbox disables outbound network sockets by default, causing `SocketException: Operation not permitted` on font downloads and API.Bible streams unless custom entitlements (`com.apple.security.network.client`) are configured.
  * **No Mobile Media Controls**: Lockscreen controls and background audio service wrappers are mobile-only and do not compile to desktop targets without desktop-specific plugins.

---

## 3. Storage, Caching, and Licensing Boundaries

### WhisperX Timestamps & Metadata
* **Uniform Behavior Across All Platforms**: All platforms read WhisperX timestamp JSON bundles from Flutter's `rootBundle` (`assets/timestamps/<TRANS>/<BOOK>_<CH>.json`).
* **Offline Independence**: Timestamps contain no audio streams—only numeric millisecond offsets and character ranges. As such, they are 100% offline-ready across Android, iOS, and PWA, enabling sub-second excerpt clipping for all translations (including NIV).

### Audio Stream Caching
* **Public Domain Audio (BSB, WEB)**: Can be persisted to local disk storage via `path_provider` on Android and iOS, or via IndexedDB / CacheStorage in PWA.
* **Proprietary Licensed Audio (NIV from Biblica / API.Bible)**: Prohibited from permanent offline disk storage per API.Bible licensing. Operates via on-demand streaming only. When disconnected from the internet, the app falls back to local Text-to-Speech (TTS).

---

## 4. Text-To-Speech (TTS) Platform Discrepancies

| Platform | Engine | Latency | Voice Quality |
| :--- | :--- | :--- | :--- |
| **Android** | Google TTS / Device Native TTS | Low (<150ms) | High naturalness (especially Google Neural TTS engines) |
| **iOS** | `AVSpeechSynthesizer` (Siri Voices) | Ultra-low (<50ms) | Excellent naturalness with enhanced voice downloads |
| **Web / PWA** | Web Speech API (`window.speechSynthesis`) | Variable | Dependent on host browser; Chrome uses Google cloud-synthesized voices or local OS voices |
| **macOS** | `NSSpeechSynthesizer` | Low | Standard macOS system voices |
