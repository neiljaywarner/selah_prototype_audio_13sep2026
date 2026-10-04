# Linktree & Dynamic Bio-Link Distribution Plan

Strategy for managing public access URLs, store badges, and social media routing for **Selah**.

---

## 1. Linktree Free Tier vs. Developer API Evaluation

### Linktree Free Tier:
- **Cost**: \$0/month.
- **Features**:
  - Unlimited links (Web App, TestFlight, Google Play, GitHub, Feedback).
  - Social media icons (X/Twitter, Instagram, YouTube, Threads).
  - Built-in analytics (clicks, views, top performing links).
  - Instant manual URL edits in the dashboard without code changes or redeployments.
- **Limitations**:
  - **No Public API on Free Tier**: Linktree's official Developer API and webhook web integrations require a **Linktree Enterprise / Partner** contract.
  - Custom domain (`links.selahwordapp.com`) requires the Pro / Premium tier (\$9 - \$24/mo).

### Alternative Dynamic Redirect Engines (API Available on Free Tier):
If you want programmatic URL switching via API (e.g., GitHub Action or script updates destination URL automatically when a build finishes):
1. **Dub.co** (Highly Recommended open-source alternative to Bitly):
   - Generous free tier with full REST API.
   - Programmatic link creation, destination URL updating, and geo-targeting.
   - Example endpoint: `PATCH https://api.dub.co/links/{linkId}` with new `url`.
2. **Short.io**:
   - Free tier includes 1 custom domain and full REST API to update link destinations on the fly.
3. **Firebase Dynamic Links / App Links**:
   - Deep linking directly into the app (e.g. `selah.page.link/col1`).

---

## 2. Recommended Linktree Structure for Selah Launch

Create `linktr.ee/selahwordapp`:

| Priority | Link Label | Destination URL | Purpose |
| :--- | :--- | :--- | :--- |
| **1 (Top / Starred)** | **✨ Try Selah Web App Live** | `https://selahwordapp.web.app` (or GH Pages) | Zero-friction immediate browser experience |
| **2** | **🗳️ Vote on Upcoming Features** | In-app Feature Voting Sheet / UserOrient board | Direct community engagement |
| **3** | **🍏 iOS TestFlight Beta** | `https://testflight.apple.com/join/...` | Early adopter testing |
| **4** | **🤖 Android Early Access** | Google Play Internal / Open Testing link | Android testing |
| **5** | **💬 Send Feedback / Prayer Request** | Doorbell.io direct form / email | Direct creator communication |
| **6** | **⭐ Star on GitHub** | `https://github.com/neiljaywarner/selah_prototype_audio_13sep2026` | Open-source developer community |

---

## 3. Social Media Bio Snippet

> **Selah | Scripture Audio Meditation 🕊️**  
> *"Be still, and know that I am God." — Ps 46:10*  
> Loop chapters with human narration & peaceful reflection.  
> 🔗 **linktr.ee/selahwordapp**
