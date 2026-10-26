# ClubHub Supabase, web, and Android setup

ClubHub has two explicitly distinct modes:

- **Supabase mode:** the default. Email/password authentication and data operations use the configured Supabase project. Missing or invalid configuration, a missing profile, network failure, or missing migration is shown as an error; the app does not fall back to demo data.
- **Development demo mode:** explicitly selected with `--dart-define=APP_MODE=demo`. Demo accounts and data are in memory and are not saved.

The configured project URL is `https://ehntqiebgnregercxbne.supabase.co`. The app requires its public publishable key, which starts with `sb_publishable_`. **Never put a Supabase `service_role` key in a Flutter define, `.env.json`, GitHub Actions build variable, Vercel client build variable, or any other client-side setting.** The service-role key belongs only in the Supabase Edge Function secret store.

## Local Flutter development

1. In Supabase Dashboard → **Project Settings → API Keys → Publishable key**, copy the project's publishable key. Do not use a service-role key.
2. Copy [`.env.example`](../.env.example) to `.env.json` and replace `your-supabase-publishable-key` with the copied value.
3. Keep `.env.json` untracked; the repository's `.gitignore` excludes it.
4. Start the app with the compile-time configuration:

   ```sh
   flutter run --dart-define-from-file=.env.json
   ```

Without a valid URL and publishable key, live mode stops with a configuration error instead of opening demo accounts. To explicitly start the in-memory demo, run `flutter run --dart-define=APP_MODE=demo`; the login screen then identifies demo mode and displays temporary demo credentials. Registration and password reset are disabled in demo mode.

## Real student registration and login

The registration form sends the display name, department, and student ID as Supabase Auth user metadata with `signUp`; the password is sent only to Supabase Auth and is never written into `public.profiles`. The existing `auth_user_profile_created` database trigger creates the profile using `auth.users.id` as `profiles.id`, with the default `student` role, and copies the name/department/student ID into the corresponding profile columns. The app does not insert profiles directly, since profile creation is performed by this trusted database trigger and student RLS does not grant profile inserts.

When email confirmation is required, Auth returns no session after registration. ClubHub displays a confirmation message; the user must confirm the email, then sign in with the same email/password. On sign-in and restored sessions, the app reads `public.profiles` by the Auth user UUID and routes by the database role. A missing profile is reported as an error; the app does not create a demo profile or sign in locally. Logout signs out from Supabase Auth and clears the in-memory repository.

Password reset emails sent from Flutter Web redirect to the current site origin. Configure that origin (for local development, such as `http://localhost:5000`; for production, the actual deployed origin) in Supabase **Authentication → URL Configuration → Redirect URLs**. Opening a valid recovery link shows ClubHub's new-password form; a successful update returns the user to their authenticated area.

Verify a registration in Supabase Dashboard → **Authentication → Users**, then **Table Editor → profiles**. Match `profiles.id` to the Auth user's UUID and check `display_name`, `email`, `department`, and `student_id`; the expected new-user role is `student`. Duplicate emails, confirmation requirements, and connection failures are surfaced in the registration/login UI. The configured Supabase Auth endpoint has been reached from this Codespace and reports email/password signup enabled, but an actual registration and matching profile have not yet been verified. Remote schema details and RLS policies are not exposed for inspection using only the publishable key; no privileged key was used.

## Database and Auth setup

No remote project was changed as part of this work. The project already has application tables, so **do not run `supabase db push` until you have checked the remote migration history and reconciled it with the SQL files here**. In particular, migrations `001`–`003` create/seed the initial schema and are not safe to replay against pre-existing tables. Back up production data first; apply only migrations that are not already represented remotely. Migration `004` is additive and installs a transaction-serialized database guard against demoting or deleting the final administrator.

After confirming that the migration history is reconciled, migrations can be applied from a trusted local terminal:

```sh
supabase login
supabase link --project-ref ehntqiebgnregercxbne
supabase db push
```

The initial migrations define the profile-on-sign-up trigger, relational tables, constraints, indexes, RLS policies, aggregate-only membership-count function, and idempotent sample seed. Migration `004` guards the final admin in the database, including bulk and concurrent demotion/deletion attempts, and prevents new registrations for past events even when called outside the app UI. Students can update only their own display name, department, and student ID through the profile screen; RLS column grants and policies reject role changes. Students can select only their own profile and registrations, join/cancel their own memberships/registrations, and read active clubs/events and published announcements. Admin database access is guarded by `public.is_admin()` policies.

In **Authentication → URL Configuration**, set the production Site URL to the final web origin and add the development redirect URLs you actually use (for example `http://localhost:5000` and `http://localhost:8080`). Enable email/password sign-up and choose the email confirmation policy appropriate for your SMTP configuration. With confirmation required, registration displays a check-your-email confirmation state instead of claiming the user is already signed in.

### Bootstrap the first admin

1. Register the intended administrator using the normal email flow and confirm the account.
2. In the Supabase SQL Editor, signed in as the project database owner, find the exact account:

   ```sql
   select id, email
   from auth.users
   where email = 'admin@example.edu';
   ```

3. Verify that this is the intended account, then promote only that profile:

   ```sql
   update public.profiles
   set role = 'admin'
   where id = '<verified-auth-user-uuid>'
     and email = 'admin@example.edu';
   ```

   The migration permits this controlled owner-session bootstrap and server-side service-role changes. It rejects role updates from ordinary authenticated clients. Do not promote all users, publish an admin password, or place an owner/service key in the app.

## Admin Edge Function

The admin screen calls `clubhub-admin` for invitations, suspension/restoration, role changes, and account deletion. The function validates the user token, checks the caller's database-backed admin role, validates input and target IDs, and rejects self-management. Administrator accounts must first be demoted before they can be suspended; the database trigger prevents demoting or deleting the final administrator even if concurrent calls race. The service-role key is used only in the Edge Function runtime.

In Supabase Dashboard → **Project Settings → Edge Functions → Secrets**, add `SUPABASE_SERVICE_ROLE_KEY` using the project service-role key. Deploy after migrations:

```sh
supabase functions deploy clubhub-admin
```

Do not paste the service-role secret into chat, a Flutter environment file, CI build variables, or source control. Supabase provides the project URL and anon key to Edge Functions; the service-role secret must be configured separately. The client never calls Auth Admin APIs directly.

## FCRIT club and sample-announcement status

The supplied brief names **E-Cell FCRIT**. The official FCRIT website returned HTTP 403 from this environment, and no poster image was present in the supplied attachment; those assets could not be independently verified or uploaded. The idempotent seed includes only that user-supplied club name and marks it **needs administrator review**. It does not invent or claim a complete verified FCRIT club list. Confirm official club names/categories/descriptions and add them through an administrator before clearing their review flags.

The seed also inserts **FinTech Unlocked 2026** once by a stable slug, attributed to E-Cell FCRIT, with the supplied announcement text and the original October 22, 2026 date. It is explicitly labelled a **past event/sample** in the student feed. The image path remains empty; no storage URL is fabricated.

## Vercel web build (manual deployment)

Build the static web output with Flutter and only the two public client values:

```sh
flutter build web --release --dart-define-from-file=.env.json
```

The deployable static site is `build/web/`. Do not add the service-role secret to Vercel project environment variables. Flutter's default hash URL strategy keeps browser refreshes on the app entry point; do not switch to path routing unless a matching Vercel SPA rewrite is added and tested.

Vercel does not provide the Flutter SDK as a standard build dependency. Build using this repository's Flutter 3.47.8 toolchain (locally or in a controlled CI build), then upload the generated static files from `build/web`. For a CLI deployment, install the Vercel CLI, run `vercel login`, build the web app with the public values, then run `vercel deploy build/web`; link or create the Vercel project when prompted, and review the preview URL. Publish only after review with `vercel deploy build/web --prod`. For a Git-connected Vercel project, configure Framework Preset **Other**, Build Command `flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY`, and Output Directory `build/web`; that Git workflow additionally requires installing the Flutter 3.47.8 SDK in its build environment. Do not add a service-role key to project environment variables. Deployment was not performed because no Vercel CLI or authentication was available in this workspace.

## Android build and phone testing

The Android platform scaffold is included in the repository, but no local Android SDK was present in this workspace, so no APK was built here. Add the public `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as GitHub Actions **repository variables** (not secrets), then trigger **Actions → Android APK → Run workflow**. The workflow builds a release-mode APK signed with the runner's debug key and uploads it as an artifact. It is suitable for device testing only, not distribution or Play Store upload.

For a local build after installing Android Studio/SDK and accepting its licenses:

```sh
flutter doctor --android-licenses
flutter build apk --release --dart-define-from-file=.env.json
```

The APK output is `build/app/outputs/flutter-apk/app-release.apk`. Transfer it to a test phone and install it; for a USB-connected device use `flutter install`. Verify sign-up/email confirmation, login/logout/session restore, password reset, club membership, event registration/cancellation, announcement display, and an admin session after database setup. Before release, replace the example Android application ID and configure a private release signing key outside this repository.
