# Firebase Hosting Preview Channels Guide

> **Production Safety Rule**: Because live users actively meditate on `https://selahword.web.app`, all feature branches, hotfixes, and visual UI overhauls should be deployed and verified on a dedicated **Firebase Hosting Preview Channel** before deploying directly to production.

---

## 1. What Are Preview Channels?

A **Preview Channel** allows you to deploy and test web changes at a unique, temporary URL without overwriting or interfering with the live production site.

- **Live URL**: `https://selahword.web.app` (Channel: `live`)
- **Preview URL**: `https://selahword--<channel-name>-<random-hash>.web.app` (Channel: `<channel-name>`)
- **Search Engine Safe**: Preview channels automatically emit `x-robots-tag: noindex`, preventing Google or other crawlers from indexing experimental or pre-release features.
- **Automatic Expiration**: Preview channels expire automatically (default: 7 days), preventing abandoned deployments.

---

## 2. Quickstart: Deploying a Preview Channel

Run the following command from the workspace root:

```bash
# 1. Build the production Flutter Web bundle
flutter build web --release

# 2. Deploy to a named preview channel (e.g. preview_v0_3_1 or staging)
firebase hosting:channel:deploy preview_name
```

### Example Output

```text
✔  hosting:channel: Channel preview_v0_3_1 has been created on site selahword.
=== Deploying to 'selahwordapp'...
✔  hosting[selahword]: file upload complete
✔  hosting[selahword]: release complete

✔  Deploy complete!
✔  hosting:channel: Channel URL (selahword): https://selahword--preview-v0-3-1-a15pcecz.web.app [expires 2026-10-19 01:22:51]
```

---

## 3. CLI Command Reference

### List All Active Channels

Inspect which preview channels are currently live, their target URLs, and when they expire:

```bash
firebase hosting:channel:list --site selahword
```

Output:
```text
Channels for site selahword

┌────────────────┬─────────────────────┬────────────────────────────────────────────────────┬─────────────────────┐
│ Channel ID     │ Last Release Time   │ URL                                                │ Expire Time         │
├────────────────┼─────────────────────┼────────────────────────────────────────────────────┼─────────────────────┤
│ preview-v0-3-1 │ 2026-10-12 01:22:51 │ https://selahword--preview-v0-3-1-a15pcecz.web.app │ 2026-10-19 01:22:51 │
├────────────────┼─────────────────────┼────────────────────────────────────────────────────┼─────────────────────┤
│ live           │ 2026-10-12 01:16:18 │ https://selahword.web.app                          │ never               │
└────────────────┴─────────────────────┴────────────────────────────────────────────────────┴─────────────────────┘
```

---

### Custom Expiration Time (`--expires`)

Customize how long the temporary URL remains reachable. Supported units are `h` (hours), `d` (days), and `m` (minutes):

```bash
# Keep preview live for 24 hours (ideal for fast PR verification)
firebase hosting:channel:deploy pr-89 --expires 24h

# Keep preview live for 14 days (ideal for client/beta staging review)
firebase hosting:channel:deploy beta-v0-4-0 --expires 14d

# Maximum expiration is 30 days (30d)
firebase hosting:channel:deploy long-term-qa --expires 30d
```

---

### Delete a Preview Channel

Manually teardown a preview channel immediately once verification is complete:

```bash
firebase hosting:channel:delete preview-v0-3-1 --site selahword
```

---

### Zero-Rebuild Promotion to Live (`firebase hosting:clone`)

Once a preview channel is approved and verified by QA, you can promote that exact immutable artifact to the live site in seconds without rebuilding:

```bash
firebase hosting:clone selahword:preview-v0-3-1 selahword:live
```

---

## 4. Testing Checklist for Preview Channels

When validating a preview URL (`https://selahword--<preview_name>-<hash>.web.app`):

| Test Item | Verification Method | Expected Outcome |
| :--- | :--- | :--- |
| **HTTP Status & Headers** | `curl -I <preview_url>` | Returns `HTTP/2 200` with `x-robots-tag: noindex` |
| **Audio Playback** | Browser desktop / mobile | BSB and WEB audio narrations stream cleanly |
| **Licensed / Offline Logic** | Switch to NIV translation | Correct license/TTS notice displays without "Offline / Airplane Mode" banner |
| **Firebase Analytics** | Open DevTools Console or Firebase DebugView | `gtag` events fire with `debug_mode: true` |
| **Responsive UI** | Mobile viewport (iPhone / Android) & Tablet | No RenderFlex overflow; player controls accessible |
| **PWA Service Worker** | Chrome DevTools > Application > Service Workers | Registers cleanly on temporary origin without cache poisoning |

---

## 5. Continuous Integration (GitHub Actions)

In automated PR workflows, preview channels can be automatically provisioned for every pull request:

```yaml
# .github/workflows/preview_channel.yml
name: Deploy Web Preview on PR

on:
  pull_request:
    branches: [ main ]

jobs:
  deploy_preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP }}'
          projectId: selahwordapp
          channelId: 'pr-${{ github.event.number }}'
          expires: 7d
```

---

## 6. Known Gotchas & Troubleshooting

1. **Firebase Authentication Authorized Domains**:
   - Preview channel subdomains are generated dynamically (e.g., `selahword--pr-89-abc1234.web.app`).
   - If using Firebase Auth Google Sign-in or OAuth, add `*.web.app` or authorize specific domains in the [Firebase Authentication Console](https://console.firebase.google.com/project/selahwordapp/authentication/providers).

2. **API.Bible CORS & Key Restrictions**:
   - If API.Bible keys are locked down by HTTP Referer, ensure `*.web.app` is permitted in the API key restrictions on developer.api.bible.

3. **Service Worker Scoping**:
   - Preview channels run on distinct subdomains, ensuring service worker caches for preview channels never pollute or collide with the production `selahword.web.app` cache.
