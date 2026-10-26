# ClubHub

ClubHub is a Flutter app for campus clubs, events, announcements, student accounts, and administrator management.

## Run locally

Flutter 3.47.8 / Dart 3.13.7 is used by the project and CI. Live mode is the default and requires Supabase configuration. Copy [`.env.example`](.env.example) to `.env.json`, replace the placeholder with the project's **publishable** key, then run:

```sh
flutter pub get
flutter run --dart-define-from-file=.env.json
```

To explicitly run the in-memory development demo instead:

```sh
flutter run --dart-define=APP_MODE=demo
```

The publishable key is available in Supabase Dashboard → **Project Settings → API Keys → Publishable key**. Do not place a service-role or database-owner key in the Flutter app. See [the setup and deployment guide](docs/supabase_setup.md) for migrations, Edge Function deployment, admin bootstrap, Vercel web builds, and Android testing.

The ignored local `.env.json` is configured for the supplied project and must not be committed. Live mode does not fall back to demo credentials when configuration is missing. Email-confirmation and database verification steps are in [the setup guide](docs/supabase_setup.md#real-student-registration-and-login). Students can edit allowed profile fields, but not their role. The Supabase Auth endpoint is reachable and email/password signup is enabled, but registration and profile-trigger behavior have not yet been verified with a real account. The Supabase CLI has no access token, Vercel CLI is not installed, and an Android SDK is not installed. No remote schema or policy inspection, migration, function deployment, or Vercel deployment has been performed. Read the setup guide before applying migrations because the database already contains tables and the initial migrations must not be blindly replayed.

## Checks

```sh
dart format lib test
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=.env.json
flutter build apk --release --dart-define-from-file=.env.json
```

The web build writes to `build/web`; the Android APK writes to `build/app/outputs/flutter-apk/`.

The Android debug-signing build is for testing only. Configure a private release signing key outside this repository before distributing an APK.
