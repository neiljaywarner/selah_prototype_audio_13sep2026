# Using Flutter Flavors & Environment Switching

This guide explains how to configure Flutter build flavors and environment defines to seamlessly switch between **Development**, **Staging**, and **Production**, and swap BaaS providers (Firebase vs. Supabase vs. Appwrite).

---

## 1. Flavor Overview

Flavors allow you to compile different variants of Selah with:
- Unique App IDs (e.g. `com.selahwordapp.dev` vs `com.selahwordapp.audio`).
- Separate backend projects (Dev Firebase/Supabase vs Prod).
- Custom app names ("Selah Dev" vs "Selah").

---

## 2. Using `--dart-define` for Zero-Native-Friction Switching

The cleanest modern Flutter pattern (and web-compatible) is using `--dart-define`:

```bash
# Development (with mock or local BaaS)
flutter run -d chrome \
  --dart-define=APP_ENV=dev \
  --dart-define=BAAS_PROVIDER=firebase \
  --dart-define=API_BIBLE_KEY=$DEV_API_BIBLE_KEY

# Staging (with Supabase or Firebase Staging)
flutter run -d chrome \
  --dart-define=APP_ENV=staging \
  --dart-define=BAAS_PROVIDER=supabase \
  --dart-define=API_BIBLE_KEY=$STAGING_API_BIBLE_KEY

# Production
flutter build web --release \
  --dart-define=APP_ENV=prod \
  --dart-define=BAAS_PROVIDER=firebase \
  --dart-define=API_BIBLE_KEY=$API_BIBLE_KEY \
  --dart-define=APTABASE_KEY=$APTABASE_KEY
```

In Dart:
```dart
const String kAppEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
const String kBaaSProvider = String.fromEnvironment('BAAS_PROVIDER', defaultValue: 'firebase');

AuthRepository createAuthRepository() {
  switch (kBaaSProvider) {
    case 'supabase':
      return SupabaseAuthRepository();
    case 'appwrite':
      return AppwriteAuthRepository();
    case 'firebase':
    default:
      return FirebaseAuthRepository();
  }
}
```

---

## 3. Native Android & iOS Flavors Setup

### Android (`android/app/build.gradle`):
```groovy
flavorDimensions "default"

productFlavors {
    dev {
        dimension "default"
        applicationIdSuffix ".dev"
        resValue "string", "app_name", "Selah (Dev)"
    }
    staging {
        dimension "default"
        applicationIdSuffix ".staging"
        resValue "string", "app_name", "Selah (Staging)"
    }
    prod {
        dimension "default"
        resValue "string", "app_name", "Selah"
    }
}
```

### iOS Schemes (Xcode):
1. In Xcode, duplicate the `Runner` scheme into `dev`, `staging`, and `prod`.
2. Assign respective Bundle Identifiers (`com.selahwordapp.dev`, `com.selahwordapp.staging`, `com.selahwordapp.audio`).
3. Run via CLI:
```bash
flutter run --flavor dev -t lib/main.dart
flutter run --flavor prod -t lib/main.dart
```
