# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

DeenRoutine — a Flutter + Firebase habit/spirituality tracker (habits with streaks, prayer times, a daily Qur'an/hadith quote, and an Islamic-knowledge quiz). Package name `com.ZakiFaiaz.deenroutine`. English and Bangla localization.

## Commands

```bash
flutter pub get                    # install/update Dart deps (run after editing pubspec.yaml)
flutter run                        # run on a connected device/emulator
flutter run -d <deviceId>          # target a specific device (`flutter devices` to list)
flutter analyze                    # static analysis (flutter_lints, see analysis_options.yaml)
flutter test                       # run tests in test/
flutter test test/widget_test.dart # run a single test file
flutter gen-l10n                   # regenerate lib/l10n/app_localizations*.dart after editing .arb files
```

`generate: true` in pubspec.yaml also runs l10n codegen automatically on `flutter run`/`build`, so `gen-l10n` is mainly for a quick regen without a full build.

Content (quiz questions, daily quotes) is edited as JSON and pushed to Firestore with Node scripts, not through the app:

```bash
npm install                # installs firebase-admin, needed once for the scripts below
npm run seed:quiz          # push data/quiz_questions.json -> QuizQuestions
npm run seed:quiz:check    # validate + dry-run, writes nothing
npm run seed:quiz:prune    # push, and delete Firestore docs removed from the file
npm run seed:quotes        # push data/daily_quotes.json -> DailyQuotes (same :check/:prune variants)
```

These require `scripts/serviceAccountKey.json` (a Firebase service account key; gitignored, never commit it) — see [data/README.md](data/README.md) for the one-time setup and the content-format rules the scripts enforce.

`test/widget_test.dart` is still the default `flutter create` counter-app boilerplate — it doesn't exercise this app and will fail if run as-is. There is no real test suite yet.

## Architecture

**Layering**: `Screen` (widget, reads a provider via `context.watch`/`context.read`) → `Provider` (`ChangeNotifier`, holds UI state, calls a service, exposes typed errors) → `Service` (talks to Firebase/HTTP, no Flutter imports, no `BuildContext`) → `Model` (`toMap`/`fromMap` for Firestore). Every feature — habits, prayer times, quiz, auth — follows this same shape; look at `HabitProvider`/`FirestoreService`/`Habit` as the reference instance before touching another feature.

**Typed errors, localized separately**: providers/services never build user-facing strings — they set a `FooErrorType` enum (e.g. `HabitErrorType`, `PrayerErrorType`) plus an untranslated detail string, because they must stay `AppLocalizations`/`BuildContext`-free. A sibling `lib/utils/foo_error_messages.dart` function maps the enum to a localized string at the point the UI displays it (`habitErrorMessage(l10n, type, detail)`). Add a new error type there, not as an ad-hoc string in the provider.

**App bootstrap** (`lib/main.dart` → `lib/app.dart`): `Firebase.initializeApp` and `NotificationService().init()` run before `runApp`. `DeenRoutineApp` wraps everything in a `MultiProvider` (Auth/Habit/Prayer/Theme/Locale), and `_AuthGate` switches between `LoginScreen` and `DashboardScreen` purely off `AuthProvider.isLoggedIn` — there's no separate router/route table.

**Firestore collections** (see `firestore.rules` for the authoritative access model): `Users`, `Habits`, `HabitLogs`, `QuizQuestions`, `QuizResults`, `DailyQuotes`, `PrayerCache`, `Notifications`, `Settings`. Most are owner-only via a `uid` field check against `request.auth.uid`; `QuizQuestions`/`DailyQuotes` are public-read/admin-write content libraries; `PrayerCache` and `HabitLogs` are shared/any-authenticated-user. Composite indexes (`QuizResults` by uid+score, `HabitLogs` by habitId+date) are defined in `firestore.indexes.json` — adding a new compound `where`+`orderBy` query elsewhere will likely need a new entry there.

**Content pipeline for QuizQuestions/DailyQuotes**: the JSON files under `data/` are the source of truth, not Firestore directly — edit the JSON, run the matching `npm run seed:*` script. Both collections use a sampling trick to avoid downloading the whole bank: quiz questions carry a `random` field evenly spaced across `[0,1)` so a quiz draws via `random >= pivot` cursor queries; daily quotes carry a stable `dayIndex` so the dashboard does a single `dayNumber % count` lookup keyed off a UTC day count from a fixed epoch (`FirestoreService._epoch`). Documents added by hand in the Firebase console are invisible to both queries since they lack these fields — always go through the seed scripts.

**Prayer times** (`PrayerService`): fetched from the public Aladhan REST API by geolocation, then cached in Firestore's `PrayerCache` keyed by `date_lat_lng` (lat/lng rounded to 2 decimals) so repeat lookups for the same day/area skip the network call. `PrayerProvider.orderedTimings` rotates the fixed Fajr→Isha order so the next upcoming prayer is always first.

**Notifications** (`NotificationService`): habit reminders use `flutter_local_notifications` + exact `AlarmManager` scheduling (`AndroidScheduleMode.exactAllowWhileIdle`). Two Android-specific things that aren't obvious from the Dart code alone:
- `tz.setLocalLocation(...)` must be called with the device's real IANA timezone (via `flutter_timezone`) before scheduling — without it, `tz.local` defaults to UTC and every reminder fires offset by the device's UTC offset instead of at the picked time.
- `SCHEDULE_EXACT_ALARM` is declared in `AndroidManifest.xml`, but on Android 13+ (API 33+) that alone doesn't grant it — the user has to enable "Alarms & reminders" for the app in system settings (or it's granted for testing via `adb shell appops set <pkg> SCHEDULE_EXACT_ALARM allow`). Scheduling calls are wrapped in try/catch so a missing grant fails the reminder silently rather than blocking the habit save.

**Habit streaks**: computed client-side in `FirestoreService.calculateStreak` from `HabitLogs` (not stored as a counter). It walks backward day-by-day from today; today not yet being logged doesn't break the streak, only a fully missed day does. For a `HabitFrequency.specificDays` habit, a day that isn't in `selectedDays` is skipped rather than counted as a miss — `calculateStreak` takes the habit's `frequency`/`selectedDays` (via `HabitProvider.streakFor(habit)`) to know which days actually count.

**Localization**: `lib/l10n/app_en.arb` / `app_bn.arb` are the source strings (`l10n.yaml` configures `app_en.arb` as the template); `app_localizations*.dart` are generated and shouldn't be hand-edited. Add new strings to both `.arb` files, then regenerate.
