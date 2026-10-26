# Execution Runbook for Lower-Cost LLM (`flash` / `flash_lite`): Deploy & Continuous QA

> **Purpose:** Step-by-step deterministic instructions for a fast, lower-cost LLM to complete:
> 1. **Firebase Web Hosting (`selahword.web.app`) & Preview Channel Deployment**
> 2. **Firebase App Distribution (`distribute_android_release.sh`) for Android Release APK**
> 3. **Continuous E2E Testing with Marionette MCP & Maestro**
> 4. **Filing GitHub Issues via GitHub MCP Server as bugs/polish items are found**

---

## 🔑 Step 0: Complete Firebase Auth for `selahwordapp` (`njwandroid@gmail.com`)

### Why Firebase CLI Returned HTTP 403 Earlier:
This new Apple Silicon Mac was logged into Firebase CLI as `neilwarner@gmail.com` (used for `belongonthespectrum`), whereas the Firebase project **`selahwordapp`** (Hosting site `selahword` and App ID `1:228765786696:android:edf812ba8fc701fe382e7d`) is owned by **`njwandroid@gmail.com`**.

### How to Complete Login:
1. If the user provides an `authCode` in chat from the Firebase login link (Session ID: `89DAA`), immediately call the `firebase` MCP tool `firebase_login`:
   ```json
   {
     "authCode": "<CODE_FROM_USER>"
   }
   ```
2. Alternatively, if the user ran `firebase login:add njwandroid@gmail.com` or `firebase login --reauth` in their terminal, verify access with:
   ```bash
   firebase projects:list
   ```

---

## 🌐 Step 1: Build & Deploy Production Web App (`https://selahword.web.app`)

1. **Compile Web Release Bundle with Environment Keys from `~/.zshrc`:**
   *(Do not print secret values to stdout)*
   ```bash
   cd /Users/neil/selah/selah_prototype_audio_13sep2026
   python3 -c '
   import os, re, subprocess
   zshrc = open(os.path.expanduser("~/.zshrc"), errors="ignore").read()
   def get_key(name):
       m = re.search(rf"{name}=[\"\x27]?([A-Za-z0-9_\-]+)[\"\x27]?", zshrc)
       return m.group(1) if m else ""
   cmd = ["flutter", "build", "web", "--release"]
   for k in ["ESV_API_KEY", "API_BIBLE_KEY", "APTABASE_KEY"]:
       v = get_key(k)
       if v: cmd.append(f"--dart-define={k}={v}")
   subprocess.run(cmd, check=True)
   '
   ```
2. **Deploy to Firebase Hosting (Preview + Main Site):**
   ```bash
   cd /Users/neil/selah/selah_prototype_audio_13sep2026
   # 1. Deploy preview channel
   firebase hosting:channel:deploy esv-soft-launch --project selahwordapp --expires 7d
   # 2. Deploy main production site (https://selahword.web.app)
   firebase deploy --only hosting --project selahwordapp
   ```

---

## 📦 Step 2: Build & Distribute Android Release APK via `scripts/distribute_android_release.sh`

1. **Run `scripts/distribute_android_release.sh` with keys loaded from `~/.zshrc`:**
   ```bash
   cd /Users/neil/selah/selah_prototype_audio_13sep2026
   python3 -c '
   import os, re, subprocess
   zshrc = open(os.path.expanduser("~/.zshrc"), errors="ignore").read()
   env = os.environ.copy()
   for k in ["ESV_API_KEY", "API_BIBLE_KEY", "APTABASE_KEY"]:
       m = re.search(rf"{k}=[\"\x27]?([A-Za-z0-9_\-]+)[\"\x27]?", zshrc)
       if m: env[k] = m.group(1)
   subprocess.run([
       "./scripts/distribute_android_release.sh",
       "--notes", "ESV 1.0 Soft Launch: Crossway David Cochran Heath human narrator audio for all passages (1 Cor 13:4-7, 1 Peter 5:7-9), zero TTS for ESV, clean ESV-only default UI."
   ], env=env, check=True)
   '
   ```
   *(Note: If Firebase auth is not yet completed, pass `--dry-run` first so `build/app/outputs/flutter-apk/app-release.apk` is pre-built and ready!)*

---

## 🧪 Step 3: Continuous QA Testing with Marionette MCP & Maestro

### A. Marionette MCP Server Testing (Connected to Pixel 9a `58221JEBF20835`)
1. Find the active Dart VM Service URI from logcat:
   ```bash
   adb -s 58221JEBF20835 logcat -d | grep "The Dart VM service is listening on" | tail -n 1
   ```
2. Forward the port:
   ```bash
   adb -s 58221JEBF20835 forward tcp:<PORT> tcp:<PORT>
   ```
3. Call `marionette:connect` with `ws://127.0.0.1:<PORT>/<TOKEN>/ws`.
4. Test the following scenarios systematically using `get_interactive_elements`, `tap`, `enter_text`, `scroll_to`, and `take_screenshots`:
   - **Scenario 1 (Curated Chips):** Tap each curated chip (`1 Cor 13:4–7`, `Matt 11:28–30`, `Rom 8:31–39`, `Psalm 23`, `1 Peter 5:7–9`). Verify each loads ESV text, shows `🎙️ Human Narrator`, shows `ESV` badge, and plays audio (`Slider` max > 0).
   - **Scenario 2 (Arbitrary Verse & Range Search):** Enter `Psalm 46:10`, `Phil 4:6-7`, `Isa 40:31`, `Gen 1:1-3`. Verify each plays human audio without TTS fallback.
   - **Scenario 3 (Loop & Silence Gap):** Cycle the loop chip (`1x`, `3x`, `7x`, `∞`) and verify state updates cleanly.
   - **Scenario 4 (Sleep Timer & Speed):** Tap `1.0x` speed chip and sleep timer moon icon; verify modals open cleanly without overflow.
   - **Scenario 5 (Settings Preview Flag):** Open Settings gear icon, verify `Preview: API.Bible narrator translations` is OFF by default. Toggle it ON, verify `BSB`, `WEB`, `NIV` and `🔀` Shuffle appear; toggle it back OFF, verify UI returns to ESV-only.

### B. Maestro E2E Flows
Run the Maestro flows on Pixel 9a (`58221JEBF20835`):
```bash
cd /Users/neil/selah/selah_prototype_audio_13sep2026
/Users/neil/.maestro/bin/maestro --device 58221JEBF20835 test .maestro/esv_verse_lookup_flow.yaml
/Users/neil/.maestro/bin/maestro --device 58221JEBF20835 test .maestro/pixel9a_smoke.yaml
```

---

## 🐛 Step 4: File Issues via GitHub MCP Server

Whenever any UI glitch, edge-case bug, truncation, or audio/search issue is discovered during Step 3:
1. Check existing issues first using `github:search_issues` (`owner: "neiljaywarner"`, `repo: "selah_prototype_audio_13sep2026"`).
2. Create a well-structured issue using `github:issue_write` (`method: "create"`, `owner: "neiljaywarner"`, `repo: "selah_prototype_audio_13sep2026"`) with:
   - Clear title (`fix(esv): ...` or `ux(player): ...`)
   - Reproduction steps
   - Expected vs. actual behavior
   - Device/platform context (`Pixel 9a / Android` or `Chrome PWA`)
3. Log every discovered issue and test milestone in `status.md`.
