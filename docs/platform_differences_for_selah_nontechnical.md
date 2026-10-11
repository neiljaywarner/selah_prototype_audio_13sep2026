# Non-Technical Guide: Platform Differences for Selah

**Audience**: Product Managers, Users, Donors, and Ministry Partners  
**Purpose**: An easy-to-read explanation of how Selah behaves on your phone, in your web browser, and on your computer.

---

## 1. Quick Summary (In Plain English)

| Platform | Best For | What to Expect | Is It for Normal Users? |
| :--- | :--- | :--- | :--- |
| **Android Phone (e.g. Pixel, Samsung)** | Walking, Commuting, Sleeping | **The Best Experience**. Plays smoothly with screen locked, seamless looping, pause/play on your lock screen. | **YES — Primary Target** |
| **iPhone (iOS)** | Walking, Commuting, Sleeping | **Flagship Experience**. Plays in your pocket with AirPods controls and lock screen widget. | **YES — Primary Target** |
| **PWA (Installed Web App)** | Instant Access on Any Phone or Tablet | You open a website, tap "Install to Home Screen", and it acts just like an app—no App Store login needed! | **YES — Primary Web Target** |
| **Web Browser (Chrome, Safari, Edge)** | Quick desktop test or preview | Great for a fast demonstration. If you switch tabs, audio might pause depending on browser rules. | **YES — For Previews** |
| **Desktop (Mac, Windows, Linux)** | Software Developers Only | Used by our programming team to build and test code quickly on their laptops. | **NO — Development Only** |

---

## 2. The Big Differences You'll Notice

### 1. Walking with Your Phone in Your Pocket ("Lockscreen Mode")
* **Android & iPhone**: You tap Play, turn off your screen, and put your phone in your pocket. The audio keeps playing, repeats continuously, and gives you quiet pauses to pray between loops. You can pause or adjust volume right from your lock screen without unlocking your phone.
* **Web Browser**: If you close your browser or turn off your screen, the web browser might pause the audio to save battery.
* **Installed PWA**: On Android phones, an installed PWA can keep playing audio in the background and show playback controls in your notification bar.

### 2. Audio Precision & "The DJ Effect" (WhisperX Alignment)
* Whole-chapter Bible audio is like a 5-minute song, but you only want to meditate on verses 28 to 30 (about 23 seconds).
* **On Android & iPhone**: The audio engine acts like a laser: it starts playing on the exact syllable of verse 28 without any awkward pauses or delay.
* **On Web Browsers**: Browsers are a bit clunkier with audio buffers. It works, but mobile phones give a much tighter, smoother transition when repeating.

### 3. What Happens Offline (Airplane Mode)?
* **Word Timestamps**: All verse timing information is bundled right into the app. Even without Wi-Fi, the app knows the exact verse numbers and boundaries.
* **Public Domain Audio (BSB, WEB)**: Can be stored on your device for true offline listening anywhere in the world.
* **Licensed Narrators (NIV)**: Copyright rules for the NIV require online streaming. If you go completely offline, Selah automatically switches to a high-quality computerized voice so you never lose your meditation.

### 4. Why Isn't Selah Distributed on Mac, Windows, or Linux App Stores?
* Selah is designed for **active movement (walking, driving) and quiet bedtime meditation (phone on nightstand)**.
* Nobody takes a desktop computer on a morning walk in the park!
* Our engineering team uses the Mac and Windows versions solely to test code fast on their development machines. We will not be releasing Selah on the Mac App Store or Windows Store.
