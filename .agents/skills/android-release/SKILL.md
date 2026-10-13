---
name: android-release
description: >-
  Guides and automates Android APK compilation, versioning, and distribution to Firebase App Distribution tester groups (such as core-testers).
---

# Android Release & Distribution Skill

Use this skill whenever building an Android release, bumping app version codes, managing Firebase App Distribution tester groups, or distributing new APK builds to meditator beta testers.

---

## 1. Architecture & Group Governance

Selah uses **Firebase App Distribution** for rapid, secure Android beta distribution.

### Core Tester Group
- **Group Display Name**: `Core Testers`
- **Group Alias**: `core-testers`
- **Current Group Members**:
  - `neilwarner@gmail.com`
  - `twinsflora1@gmail.com`
- **Firebase Project ID**: `selahwordapp`
- **Android App ID**: `1:228765786696:android:edf812ba8fc701fe382e7d`

---

## 2. Managing Tester Groups

### Add New Testers to the Project & Group
To invite a new tester and ensure they receive all builds automatically:
```bash
firebase appdistribution:testers:add <email> \
  --group-alias core-testers \
  --project selahwordapp
```

### Create a New Group
```bash
firebase appdistribution:group:create "<Display Name>" <alias> \
  --project selahwordapp
```

---

## 3. Automated Distribution Workflow

The repository includes a dedicated release script:
[`scripts/distribute_android_release.sh`](../../scripts/distribute_android_release.sh)

### Standard Release (Builds & Distributes to `core-testers`):
```bash
./scripts/distribute_android_release.sh --notes "Added on-device voice engine optimization and copyright transparency."
```

### Dry Run (Builds APK without uploading):
```bash
./scripts/distribute_android_release.sh --dry-run
```

### Distribute to Custom / Additional Groups:
```bash
./scripts/distribute_android_release.sh --groups "core-testers,pastors-panel" --notes "Pre-release review."
```

---

## 4. Optional Fastlane Integration

For continuous delivery environments, a `Fastfile` lane can encapsulate this pipeline:

```ruby
default_platform(:android)

platform :android do
  desc "Build and distribute release APK to Firebase App Distribution"
  lane :distribute_android do |options|
    sh("flutter build apk --release")

    firebase_app_distribution(
      app: "1:228765786696:android:edf812ba8fc701fe382e7d",
      apk_path: "build/app/outputs/flutter-apk/app-release.apk",
      groups: options[:groups] || "core-testers",
      release_notes: options[:notes] || "Automated build via Fastlane"
    )
  end
end
```

---

## 5. Pre-Release Verification Protocol

Before distributing any release build:
1. **Analyze & Test**:
   ```bash
   flutter analyze
   flutter test
   ```
2. **Verify Version Bump**:
   Inspect `pubspec.yaml` to ensure `version: X.Y.Z+BUILD` has incremented build number.
3. **Verify Git Hygiene**:
   Ensure `git status` has zero unstaged API keys, tokens, or plaintext secrets.
4. **Post-Upload Verification**:
   Inspect the App Distribution console URL or check device notification on tester devices.
