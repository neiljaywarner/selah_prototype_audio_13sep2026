# Marionette UI Automation Guide: Selah Scripture Audio Meditation

This guide explains how human developers and AI pair-programming agents drive and verify the **Selah Scripture Audio Meditation** application using the [Marionette MCP server](https://github.com/google) and Android `adb` tooling.

---

## 1. Overview & Purpose

Marionette is a Model Context Protocol (MCP) server that connects to a Flutter application running in debug mode via Dart's VM Service WebSocket (`ws://127.0.0.1:<port>/ws`).

In Selah's ticket-driven workflow:
- **Visual Evidence**: Every customer-facing PR and major milestone must include visual verification artifacts (screenshots and/or screen recordings).
- **Multi-Platform Testing**:
  1. **Chrome (PWA)**: Our primary web deployment target.
  2. **Android (Physical Pixel 9a)**: Our flagship mobile target.
  3. **Desktop (macOS)**: Rapid local developer verification.
- **Before / After Comparison**: Whenever a UI or layout change is made, capture before and after screenshots and present them in a Markdown/HTML table.

---

## 2. Prerequisites & Environment Setup

### A. Physical Device (Google Pixel 9a)
1. Ensure the Pixel 9a is connected via USB with Developer Options & USB Debugging enabled:
   ```bash
   adb devices
   # Output should list: 58221JEBF20835  device
   ```
2. Port-forward the VM service port if needed:
   ```bash
   adb forward tcp:8181 tcp:8181
   ```

### B. Chrome (PWA Target)
Launch Selah in Chrome debug mode:
```bash
flutter run -d chrome --web-port=8080
```

### C. macOS Desktop Target
Launch Selah in macOS desktop mode:
```bash
flutter run -d macos
```

---

## 3. Marionette MCP Tool Reference

| MCP Tool | Purpose | Key Arguments |
| :--- | :--- | :--- |
| `connect` | Attach to running Flutter VM service | `{"vm_service_uri": "ws://127.0.0.1:8181/ws"}` |
| `get_interactive_elements` | Discover UI widgets, Semantics, text, and keys | `{"ancestor_keys": [...]}` (optional scope) |
| `tap` | Tap a button, chip, or list item | `{"key": "preset_chip_1co"}` or `{"text": "1 Cor 13:4–7"}` |
| `enter_text` | Enter text into search or input fields | `{"text": "col 1:17-20", "key": "search_input"}` |
| `scroll_to` | Scroll horizontally or vertically to a widget | `{"key": "preset_psalm23"}` |
| `take_screenshots` | Capture high-resolution screenshot from VM service | `{}` |
| `hot_reload` | Trigger instant Flutter hot reload | `{}` |
| `hot_restart` | Trigger full Flutter restart from `main()` | `{}` |
| `disconnect` | Detach VM service session | `{}` |

---

## 4. Capturing Visual Verification Artifacts via ADB

For physical Android devices (like the attached Pixel 9a `58221JEBF20835`), `adb` can capture screenshots and screen recordings directly from the shell:

### Capturing Screenshots:
```bash
# Capture directly to local artifact directory
adb -s 58221JEBF20835 exec-out screencap -p > docs/artifacts/screenshots/pixel9a_curated_chips.png
```

### Recording Video:
```bash
# Record up to 15 seconds of interaction
adb -s 58221JEBF20835 shell screenrecord --time-limit 15 /sdcard/selah_demo.mp4
# Pull the recording to local machine
adb -s 58221JEBF20835 pull /sdcard/selah_demo.mp4 docs/artifacts/videos/selah_curated_demo.mp4
# Clean up device storage
adb -s 58221JEBF20835 shell rm /sdcard/selah_demo.mp4
```

---

## 5. Standard PR Verification Table Template

In PR descriptions and comments, format visual artifacts using this standard layout:

```html
<table>
  <tr>
    <th align="center">Curated Demo Chips (1 Cor 13, Matt 11, Rom 8, Psalm 23)</th>
    <th align="center">Uncurated Range Guardrail (col 1:17-20 SnackBar)</th>
  </tr>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/..." width="360" alt="Curated Demo Chips" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/..." width="360" alt="Coming Soon SnackBar" />
    </td>
  </tr>
</table>
```

---

## 6. Common Issues & Troubleshooting

1. **`Connection refused` on `connect`**:
   Ensure `flutter run` printed the Observatory / VM Service URI, and verify whether `adb forward tcp:<local_port> tcp:<remote_port>` is required for Android.
2. **Widget not found by text**:
   Widgets formatted with rich styling or typography (like `GoogleFonts.newsreader`) may need `ValueKey` identifiers or exact substring matching. Use `get_interactive_elements` to inspect the live accessibility and element hierarchy.
3. **PWA Background Audio Limitations**:
   Chrome PWA audio policies require a user gesture before starting audio playback. On Android Chrome PWA, lockscreen controls are powered by the Media Session API, whereas native Android uses foreground services (`just_audio_background`).
