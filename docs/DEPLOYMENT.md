# RideGo — Deployment & Distribution Guide

This document outlines deployment procedures for the RideGo cross-platform application across Android mobile devices and Flutter Web.

---

## 1. Android Release Build & Installation

### Build Command
The production Android APK is generated using Flutter with compile-time configuration defines:

```powershell
$env:PATH = "C:\development\flutter\bin;$env:PATH"
flutter build apk --release --dart-define-from-file=config.prod.json
```

### Artifact Location
- Built APK path: `build/app/outputs/flutter-apk/app-release.apk`
- Architecture: Universal APK (supports `arm64-v8a`, `armeabi-v7a`, `x86_64`)

### Physical Device Installation via ADB
To install the APK on an Android device with Developer Options & USB Debugging enabled:

```powershell
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Or transfer the APK file directly to the device storage and open it to trigger the Android Package Installer.

### Production App Signing (Google Play Store)
For Play Store submission:
1. Generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` with keystore credentials (ensure this file is in `.gitignore`).
3. Build the Android App Bundle (AAB):
   ```powershell
   flutter build appbundle --release --dart-define-from-file=config.prod.json
   ```

---

## 2. Flutter Web Deployment

The web build serves as the unified interface for both Customer booking and Administrator management.

### Build Command
```powershell
$env:PATH = "C:\development\flutter\bin;$env:PATH"
flutter build web --release --dart-define-from-file=config.prod.json
```

The output is bundled into the `build/web/` directory.

### Deploying to Vercel
1. Ensure the Vercel CLI is installed (`npm i -g vercel`).
2. Run in the project directory:
   ```bash
   vercel build/web --prod
   ```
3. Add rewrite rules in `vercel.json` for client-side routing with `go_router`:
   ```json
   {
     "rewrites": [
       { "source": "/(.*)", "destination": "/index.html" }
     ]
   }
   ```

### Deploying to Firebase Hosting
1. Initialize Firebase: `firebase init hosting` (set public directory to `build/web` and configure as a single-page app).
2. Deploy:
   ```bash
   firebase deploy --only hosting
   ```

### Deploying to Supabase Storage as Static Website
1. Create a public bucket in Supabase called `$web`.
2. Upload the contents of `build/web/` to the root of the bucket.
3. Access your web portal via the Supabase project public storage URL.

---

## 3. Environment Variables & Security Checklist

When deploying to staging or production environments, verify:

| Parameter | Recommended Value | Description |
|---|---|---|
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` | Supabase API endpoint |
| `SUPABASE_ANON_KEY` | Public Anon JWT | Safe for client embedding |
| `ENABLE_DEMO_FALLBACK` | `false` (Production) | Disables sample offline seed data |

> **Critical Security Rule**: Never inject `SERVICE_ROLE_KEY` into Flutter builds. All administrative mutations are guarded by PostgreSQL RLS policies tied to the authenticated user's `is_admin` claim.
