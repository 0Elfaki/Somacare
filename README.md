# SomaCare

Student telemedicine for Flutter. Students book and attend video consultations,
keep a medical history, manage prescriptions and medications, and reach an
on-call doctor in an emergency. Doctors run their day from a matching dashboard:
schedule, emergency queue, patient records, prescriptions and earnings.

- **Backend:** Supabase (auth, Postgres, realtime, edge functions)
- **State:** Riverpod
- **Routing:** go_router
- **Video:** Agora RTC
- **AI triage:** Groq

---

## Running it

```bash
flutter pub get
flutter run
```

That works out of the box against the development Supabase project. For any
other environment, pass configuration at build time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=AGORA_APP_ID=your-agora-app-id \
  --dart-define=GROQ_API_KEY=gsk_...
```

Keeping the four values in a `--dart-define-from-file` JSON is easier than
retyping them:

```bash
flutter run --dart-define-from-file=config/dev.json
```

> The Supabase **anon** key is a public, row-level-security-scoped credential and
> is meant to ship in the client. The **service-role** key must never appear in
> this repository. `GROQ_API_KEY` is embedded in the binary and is extractable
> from a shipped app — before launch, move the Groq call behind a Supabase edge
> function the way the Agora token already is.

---

## Verifying a change

```bash
flutter analyze          # static analysis; the project treats unused imports as errors
flutter test             # design-system tests: theme, contrast, type scale, nav
dart format --output=none --set-exit-if-changed lib test
```

There is also a compiler-independent structural check that catches the classes
of breakage a large refactor introduces (unbalanced brackets, references to
design tokens that do not exist, missing imports):

```bash
python3 tools/dart_check.py .
```

### If `flutter analyze` crashes on your machine

The analysis server dying with `analysis server exited with code -1073740791`,
and Gradle producing `hs_err_pid*.log` files, are both the same problem: the
machine ran out of memory, not a fault in the code. The crash dumps in this repo
all said:

```
Native memory allocation (mmap) failed to map 130023424 bytes. Error detail: G1 virtual space
```

`android/gradle.properties` now asks for a 2 GB Gradle heap instead of 3 GB. If
it still happens:

```bash
flutter clean
dart pub cache repair          # only if packages look corrupt
flutter analyze --no-fatal-infos
```

…with other Gradle/JVM/IDE processes closed first. Android Studio and a separate
`flutter run` each hold their own analysis server.

---

## Releasing

### Android

1. Create an upload keystore once:

   ```bash
   keytool -genkey -v -keystore somacare-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (git-ignored):

   ```properties
   storeFile=C:/keys/somacare-upload.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```

3. Build:

   ```bash
   flutter build appbundle --release --dart-define-from-file=config/prod.json
   ```

Without `key.properties` the release build falls back to the **debug** key, and
Gradle says so at the start of the build. A debug-signed bundle cannot be
uploaded to Google Play.

The application id is `com.somacare.app`. It is permanent after the first
upload.

### iOS

`ios/Runner/Info.plist` carries the camera, microphone and photo-library purpose
strings. Without them iOS terminates the app the moment Agora asks for the
camera, and App Review rejects the binary.

```bash
flutter build ipa --release --dart-define-from-file=config/prod.json
```

---

## How the app is put together

```
lib/
  theme/app_theme.dart        one palette, one type scale, one ThemeData
  widgets/app_ui.dart         the shared design system both dashboards render from
  widgets/bloom_components.dart  older shared widgets, same tokens
  core/routing/app_router.dart   every route, plus the role guards
  features/
    auth/            role selection, school selection, login
    onboarding/
    student/         data/ · providers/ · presentation/
    doctor/          data/ · presentation/
```

`DESIGN_SYSTEM.md` describes the tokens and components, and the rules a new
screen has to follow to look like the rest of the app.

---

## License

**Copyright (c) 2026 Megdad Elfaki / SomaCare. All Rights Reserved.**

This repository is **source-available for viewing only**. No permission is granted to copy, modify, distribute, or deploy any portion of this code. See [LICENSE.md](LICENSE.md) for full terms.
