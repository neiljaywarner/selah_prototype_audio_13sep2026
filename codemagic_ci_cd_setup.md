# Codemagic CI/CD Setup & Automation Guide

This guide details how **Codemagic** automatically builds, tests, and deploys **Selah** for **Flutter Web**, **Android App Bundle (AAB)**, and **iOS App Store (IPA)**.

---

## ⚡ Codemagic Configuration (`codemagic.yaml`)

Add `codemagic.yaml` to the root of the repository:

```yaml
workflows:
  flutter-web-workflow:
    name: Flutter Web Deployment
    max_build_duration: 30
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      vars:
        API_BIBLE_KEY: ${API_BIBLE_KEY}
        APTABASE_KEY: ${APTABASE_KEY}
    scripts:
      - name: Get Flutter packages
        script: flutter pub get
      - name: Run unit tests
        script: flutter test
      - name: Build Web release bundle
        script: |
          flutter build web --release \
            --base-href "/selah_prototype_audio_13sep2026/" \
            --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
            --dart-define=APTABASE_KEY=$APTABASE_KEY
    publishing:
      scripts:
        - name: Deploy to GitHub Pages
          script: |
            git config user.name "Codemagic CI"
            git config user.email "ci@codemagic.io"
            npx gh-pages -d build/web

  android-release-workflow:
    name: Android App Bundle (AAB) Build
    max_build_duration: 30
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      vars:
        API_BIBLE_KEY: ${API_BIBLE_KEY}
        APTABASE_KEY: ${APTABASE_KEY}
    scripts:
      - name: Get Flutter packages
        script: flutter pub get
      - name: Run unit tests
        script: flutter test
      - name: Build Android App Bundle
        script: |
          flutter build appbundle --release \
            --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
            --dart-define=APTABASE_KEY=$APTABASE_KEY
    artifacts:
      - build/app/outputs/bundle/release/*.aab

  ios-release-workflow:
    name: iOS TestFlight & App Store IPA Build
    max_build_duration: 45
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      vars:
        API_BIBLE_KEY: ${API_BIBLE_KEY}
        APTABASE_KEY: ${APTABASE_KEY}
    scripts:
      - name: Get Flutter packages
        script: flutter pub get
      - name: Run unit tests
        script: flutter test
      - name: Build iOS IPA
        script: |
          flutter build ipa --release \
            --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
            --dart-define=APTABASE_KEY=$APTABASE_KEY
    artifacts:
      - build/ios/ipa/*.ipa
```

---

## 🛠️ Step-by-Step Activation in Codemagic Console

1. **Connect Repository**: Go to [Codemagic App Console](https://codemagic.io/apps) and select `neiljaywarner/selah_prototype_audio_13sep2026`.
2. **Add Environment Variables**:
   - `API_BIBLE_KEY` (Mark as Secure)
   - `APTABASE_KEY` (Mark as Secure)
3. **Trigger Workflow**: Codemagic will run tests, build Android/iOS release packages, and publish the web app on every push to `feat/*` or `main`.
