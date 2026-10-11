# Codemagic CI/CD Deployment Guide

This guide describes how to trigger and manage automated builds for **Selah** using [Codemagic](https://codemagic.io) and [`codemagic.yaml`](../codemagic.yaml).

---

## 🏗️ Configured Workflows

The repository includes two dedicated CI/CD workflows defined in [`codemagic.yaml`](../codemagic.yaml):

| Workflow Name | ID | Target Platform | Outputs | Notifications |
| :--- | :--- | :--- | :--- | :--- |
| **Selah Web Build & Deploy** | `selah-web-build` | Web (PWA) | `build/web/**` | Email (`neilwarner@gmail.com`) |
| **Selah Android APK Build** | `selah-android-release` | Android (Release APK) | `build/app/outputs/**` | Email (`neilwarner@gmail.com`) |

Both workflows run on Codemagic's **`mac_mini_m2`** instance type with Flutter 3.29+ and execute the complete test suite (`flutter test`) before generating artifacts.

---

## 🔐 Environment Variables & Secrets

The workflows reference the `selah_secrets` environment variable group in Codemagic. Ensure these variables are configured under your app settings in the Codemagic dashboard:

1. **`API_BIBLE_KEY`**: Your API.Bible developer token for fetching Scripture audio streams and text.
2. **`APTABASE_KEY`**: Your Aptabase app telemetry key for anonymous usage events.

> [!IMPORTANT]
> Secrets must be added to the `selah_secrets` group in the Codemagic UI. No plaintext API keys are stored or committed in `codemagic.yaml`.

---

## 🚀 How to Trigger Builds Manually

1. Log into your [Codemagic Dashboard](https://codemagic.io/apps).
2. Select the **`selah_prototype_audio_13sep2026`** application.
3. Click **Start new build** in the top right corner.
4. Configure your build options:
   * **Branch:** Choose your active working branch (e.g., `v0.2_mini` or `main`).
   * **Workflow:** Select either:
     * `Selah Web Build & Deploy` (Web PWA)
     * `Selah Android APK Build` (Android APK)
5. Click **Start build**.
6. When the build succeeds or fails, an email notification containing build status and artifact download links will be sent automatically to `neilwarner@gmail.com`.

---

## 📦 Artifact Retrieval

- **Web PWA:** Download the zip artifact, extract to `build/web`, and deploy directly via `firebase deploy --only hosting` or GitHub Pages.
- **Android APK:** Download `app-release.apk` directly to test on physical Android devices.
