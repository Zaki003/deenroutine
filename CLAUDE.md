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

`test/widget_test.dart` is still the default `flutter create` counter-app boilerplate — it doesn't exercise this app and will fail if run as-is. The only real tests are `test/prayer_waqt_test.dart` and `test/prayer_stats_test.dart`, covering prayer tracking's waqt rules and stats.

## Architecture

**Layering**: `Screen` (widget, reads a provider via `context.watch`/`context.read`) → `Provider` (`ChangeNotifier`, holds UI state, calls a service, exposes typed errors) → `Service` (talks to Firebase/HTTP, no Flutter imports, no `BuildContext`) → `Model` (`toMap`/`fromMap` for Firestore). Every feature — habits, prayer times, quiz, auth — follows this same shape; look at `HabitProvider`/`FirestoreService`/`Habit` as the reference instance before touching another feature.

**Typed errors, localized separately**: providers/services never build user-facing strings — they set a `FooErrorType` enum (e.g. `HabitErrorType`, `PrayerErrorType`) plus an untranslated detail string, because they must stay `AppLocalizations`/`BuildContext`-free. A sibling `lib/utils/foo_error_messages.dart` function maps the enum to a localized string at the point the UI displays it (`habitErrorMessage(l10n, type, detail)`). Add a new error type there, not as an ad-hoc string in the provider.

**App bootstrap** (`lib/main.dart` → `lib/app.dart`): `Firebase.initializeApp` and `NotificationService().init()` run before `runApp`. `DeenRoutineApp` wraps everything in a `MultiProvider` (Auth/Habit/Prayer/Theme/Locale), and `_AuthGate` switches between `LoginScreen` and `DashboardScreen` purely off `AuthProvider.isLoggedIn` — there's no separate router/route table.

**Firestore collections** (see `firestore.rules` for the authoritative access model): `Users`, `Habits`, `HabitLogs`, `QuizQuestions`, `QuizResults`, `DailyQuotes`, `PrayerCache`, `PrayerLogs`, `Notifications`, `Settings`. Most — including `HabitLogs` — are owner-only via a `uid` field check against `request.auth.uid`; `QuizQuestions`/`DailyQuotes` are public-read/admin-write content libraries; `PrayerCache` is shared/any-authenticated-user. Composite indexes (`QuizResults` by uid+score, `HabitLogs` by uid+habitId+date, `PrayerLogs` by uid+day) are defined in `firestore.indexes.json` — adding a new compound `where`+`orderBy` query elsewhere will likely need a new entry there.

**Listeners outliving the session**: signing out or deleting the account drops the auth session while the providers' Firestore listeners are still attached, and they're rejected before `MainNavScreen.dispose` stops them. Each listener's `onError` checks `FirestoreService.isSignedInAs(uid)` first and stops quietly if the session is over, instead of surfacing a sync error (which otherwise showed as a "Couldn't sync your habits" snackbar on the login screen after deleting an account). Keep that check in any new listener.

**Firestore rules aren't a post-filter**: a `list` query is rejected outright — not silently narrowed — unless every field an `allow read` rule checks is also pinned by an equality clause in the query itself. This is why `FirestoreService.watchHabitLogs` filters on both `uid` and `habitId` even though `habitId` alone would be enough data-wise: the owner-only HabitLogs rule checks `resource.data.uid`, so any query missing a matching `uid` clause fails for every caller, not just for other users' data. Keep this in mind before adding a new `HabitLogs`/`Habits`/`QuizResults` query.

**Content pipeline for QuizQuestions/DailyQuotes**: the JSON files under `data/` are the source of truth, not Firestore directly — edit the JSON, run the matching `npm run seed:*` script. Both collections use a sampling trick to avoid downloading the whole bank: quiz questions carry a `random` field evenly spaced across `[0,1)` so a quiz draws via `random >= pivot` cursor queries; daily quotes carry a stable `dayIndex` so the dashboard does a single `dayNumber % count` lookup keyed off a UTC day count from a fixed epoch (`FirestoreService._epoch`). Documents added by hand in the Firebase console are invisible to both queries since they lack these fields — always go through the seed scripts.

**Prayer times** (`PrayerService`): fetched from the public Aladhan REST API by geolocation, then cached in Firestore's `PrayerCache` keyed by `date_lat_lng` (lat/lng rounded to 2 decimals) so repeat lookups for the same day/area skip the network call. `PrayerProvider.orderedTimings` rotates the fixed Fajr→Isha order so the next upcoming prayer is always first.

**Prayer tracking** (`PrayerLogProvider`, `lib/utils/prayer_waqt.dart`): the Prayer screen's tick circles write one `PrayerLogs` doc per user per *prayer day*, which runs Fajr to the next Fajr (so Isha logged at 12:30 AM lands on the previous date), with a field per prayer holding a `PrayerStatus` name. A tap decides the status from the clock via `prayerWindowsFor`, which is the single definition of each waqt: Fajr on time until sunrise then qada; Dhuhr and Maghrib on time until the next prayer then qada; Asr late for the 20 minutes before Maghrib (makruh time); Isha on time until Islamic midnight (halfway from Maghrib to the next Fajr, computed locally, not Aladhan's `Midnight`) then late until Fajr. Holding a circle opens a sheet to set a status by hand, for logging after the fact. Things that aren't obvious:
- It needs sunrise, which `PrayerService` returns separately from `timings` (everything iterating `timings` expects exactly the five prayers). `PrayerCache` docs and the local prefs cache from before this was added lack it, so they're treated as a miss and refetched once.
- Between midnight and Fajr the windows are built from *today's* clock times on yesterday's date - they drift a minute or two a day, well within what a tap resolves.
- Today's record is read with a `uid`+`day` query, not a document get: the owner-only rule checks `resource.data.uid`, which a not-yet-created day's doc doesn't have, so a get would be denied.
- Prayer data is deliberately private: no share card, no analytics event. An unlogged prayer is simply absent; `missed` is only ever set by hand, and nothing about it is coloured red.
- `excused` (from "Excused all day" in the hold sheet, which marks every not-yet-prayed prayer of the day at once) is left out of every percentage and pauses the streak without breaking it. It's never labelled with a reason, and the Profile grid draws it the same neutral grey as missed and unlogged, since anyone glancing at the phone can see the grid.
- The Profile's prayer section (`PrayerStatsSection`, maths in `computePrayerStats`) loads the last 90 days once per prayer day via `PrayerLogProvider.loadHistory` and merges in today's live record, so logging a prayer updates it without another fetch. Days before the first logged one are ignored rather than counted as missed. The streak can't see past the 90 days loaded, so it shows as "N+" when it reaches that far.
- This replaced the old "Pray five times" checklist habit template, which was removed from the template list; habits already created from it are untouched.

**Notifications** (`NotificationService`): habit reminders use `flutter_local_notifications` + exact `AlarmManager` scheduling (`AndroidScheduleMode.exactAllowWhileIdle`, falling back to inexact when the exact-alarm grant is missing). Every kind of notification goes through `NotificationService.schedule` with a `NotificationKind`, each with its own Android channel so a user can mute one from system settings. Two Android-specific things that aren't obvious from the Dart code alone:
- `tz.setLocalLocation(...)` must be called with the device's real IANA timezone (via `flutter_timezone`) before scheduling — without it, `tz.local` defaults to UTC and every reminder fires offset by the device's UTC offset instead of at the picked time.
- `SCHEDULE_EXACT_ALARM` is declared in `AndroidManifest.xml`, but on Android 13+ (API 33+) that alone doesn't grant it — the user has to enable "Alarms & reminders" for the app in system settings (or it's granted for testing via `adb shell appops set <pkg> SCHEDULE_EXACT_ALARM allow`). Scheduling calls are wrapped in try/catch so a missing grant fails the reminder silently rather than blocking the habit save.

**Daily ayah/hadith notification** (`NotificationSettingsProvider`, on by default, choices in SharedPreferences): scheduled as a rolling window of 7 individual notifications, not one repeating one (a repeating notification would show the same text forever), topped up on every launch/resume by `MainNavScreen` and cancelled on logout. Each carries the quote the dashboard will show at that moment — `quoteDayIndex` (`lib/utils/daily_quote_schedule.dart`) is the single definition of "which quote for which instant", counted in UTC like the dashboard's own lookup, so use it rather than a local date. It uses `inexactAllowWhileIdle`, so it works without the exact-alarm grant. Its IDs live in a fixed band starting at `NotificationService.quoteNotificationIdBase` (far above any habit-reminder `hashCode` or prayer-alarm ID) so cancelling them never touches those.

**Habit notifications** (`HabitNotificationScheduler`, driven by `NotificationSettingsProvider`): a habit's reminder is *not* scheduled by the add-habit screen and is *not* one repeating notification. The scheduler owns all of it — each habit's reminders, the streak nudge, the Friday summary, and the come-back messages — because a local notification can't change its text or check state when it fires, so everything is worked out ahead and **rebuilt whenever something changes** (app launch/resume, any habit change via a listener on `HabitProvider` in `MainNavScreen`, any setting flip). A habit gets its next 7 days scheduled individually, which is what lets the wording rotate, skip today's once the habit is done (and come back if it's undone), and skip days a `specificDays` habit isn't due. Rebuilds are debounced, one-at-a-time, and skipped when a signature of everything they depend on hasn't changed.

Things that aren't obvious from the code alone:
- IDs are derived, not stored: `habitReminderId(habitId, date)` in `lib/utils/notification_plan.dart` (FNV-1a via `stableHash`, not `String.hashCode`, whose value isn't guaranteed across SDK versions), so the same habit-day always maps to the same ID and "cancel today's" is exact. Bands are documented at the top of that file. After each run a sweep cancels any pending ID in the scheduler's ranges that the current state doesn't want, so deleted habits and removed reminders clean themselves up; it also cancels the old per-habit repeating `title.hashCode` reminders from before this design.
- The streak nudge only ever schedules the *next* evening slot, and is rebuilt on every change, so the streak number in its text is what it will really be when it fires (it looks at tomorrow's slot only when nothing's at risk tonight). It uses `HabitProvider.streakAsOf`, not `streakFor` — `streakFor` queues milestone banners as a side effect.
- The come-back messages are scheduled 4 and 10 days out on every launch, so they only fire for someone who genuinely stopped opening the app, and "at most twice" holds without a counter.
- The Friday summary only includes numbers when computed in the same Mon-Sun week as the Friday it's for; otherwise it uses the number-free wording.
- Every switch on the Notifications screen (daily quote, streak nudge, Friday summary, come-back messages, encouraging wording) is on by default; a stored SharedPreferences value only exists once the user flips one, so users who never touched a switch get the current default.
- Local scheduling caps out on iOS at 64 pending notifications; with many habits × 7 days that limit would bite. Android is unaffected in practice.

**Habit tracking types** (`HabitTrackingType` in `lib/models/habit.dart`): six types share one `Habit` row — only the config field(s) matching a habit's `trackingType` are meaningful (`numericTarget`/`numericUnit`, `timerTargetMinutes`, `checklistItems`, `ratingScale`); the rest just sit at their default. Today's raw progress (count, checklist items checked off, rating given) is denormalized onto `todayProgressValue`/`todayChecklistDone`/`todayRatingValue` alongside `completed`, gated by `hasProgressToday`, so a dashboard row can render e.g. "6/10 pages" without a separate query (`habitProgressSubtitle` reads these per type). `avoidance` has no config field of its own — it reuses the plain `completed` toggle but inverts what counts as a good day, see Habit streaks below.

**Habit streaks**: computed client-side in `FirestoreService.calculateStreak` from `HabitLogs` (not stored as a counter). It walks backward day-by-day from today; today not yet being logged doesn't break the streak, only a fully missed day does. For a `HabitFrequency.specificDays` habit, a day that isn't in `selectedDays` is skipped rather than counted as a miss — `calculateStreak` takes the habit's `frequency`/`selectedDays` (via `HabitProvider.streakFor(habit)`) to know which days actually count. `HabitTrackingType.avoidance` inverts success itself: a day with no `HabitLogs` entry is the win (nothing to avoid slipping on) and a logged entry is the break, so a slip is the only thing ever written for it — both `calculateStreak` and `weekCompletion` branch on this.

**Habit templates** (`lib/models/habit_template.dart`): a plain Dart list, not a Firestore collection — adding one is a `templateX` key in both `.arb` files plus a list entry, no seed script or release step. Picking one just pre-fills the add-habit form (`AddHabitScreen(template:)`), including `trackingType` and its config (checklist items, numeric target/unit, timer minutes) when the template sets them — it's a head start, not a locked-in choice, and there's no bulk-migration path, so changing a template's defaults later doesn't touch habits already created from it.

**Localization**: `lib/l10n/app_en.arb` / `app_bn.arb` are the source strings (`l10n.yaml` configures `app_en.arb` as the template); `app_localizations*.dart` are generated and shouldn't be hand-edited. Add new strings to both `.arb` files, then regenerate.
