DeenRoutine

Habits & Spirituality Productivity Tracker

DeenRoutine is a cross-platform mobile app that helps Muslims build consistency in both religious practice and personal development — in one place, instead of juggling a separate prayer app, a to-do list, and a Quran app. Habits sync to real, location-based prayer times, progress is visualized through the "Barakah Circle," and daily Quranic/Hadith content plus an Islamic knowledge quiz keep users engaged.

Built with Flutter and Firebase as an academic Master's (MIT) project at the Institute of Information & Communication Technology, Shahjalal University of Science & Technology — now being prepared for release on the Google Play Store.

Show Image Show Image Show Image Show Image

Features
Dual habit tracking — manage Islamic habits (Salah, Qur'an recitation, Adhkar) and personal habits (exercise, reading, hydration) side by side, with daily, weekly, or specific-weekday scheduling.
Barakah Circle — a real-time, custom-painted progress ring on the dashboard showing today's completion rate.
Prayer time sync — the day's five prayer times, fetched by geolocation via the Aladhan API and cached in Firestore to minimize network calls.
Daily motivation — a rotating Quranic verse or Hadith shown right on the dashboard, deterministically rotated per calendar day.
Islamic knowledge quiz — multiple-choice quizzes with instant scoring and historical results.
Streaks — computed from habit completion logs, not stored as a raw counter, so history stays accurate.
Reminder notifications — local, exact-alarm scheduled reminders per habit.
Light/dark theme & English/Bangla localization.
Secure, per-user data isolation enforced at the database layer via Firestore Security Rules.
Tech Stack
Layer	Technology
Frontend	Flutter (Dart ≥ 3.3.0)
State management	Provider (ChangeNotifier)
Backend	Firebase Authentication, Cloud Firestore, Cloud Messaging
Prayer times	Aladhan REST API + Geolocator
Notifications	flutter_local_notifications (exact AlarmManager scheduling)
Local persistence	SharedPreferences
Architecture

DeenRoutine follows a layered client-server architecture:

Screen (widget)  →  Provider (ChangeNotifier)  →  Service (Firebase/HTTP)  →  Model (toMap/fromMap)
Screens read state via context.watch / context.read and contain no business logic.
Providers hold UI state and expose typed errors (e.g. HabitErrorType), never localized strings directly.
Services talk to Firebase/HTTP only — no Flutter imports, no BuildContext.
Models are plain Dart classes with toMap/fromMap for Firestore serialization.

Firestore collections: Users, Habits, HabitLogs, QuizQuestions, QuizResults, DailyQuotes, PrayerCache, Notifications, Settings — see firestore.rules for the full access model.

Screenshots
<!-- Add screenshots here once available, e.g.: <p float="left"> <img src="docs/screenshots/dashboard.png" width="200" /> <img src="docs/screenshots/habits.png" width="200" /> <img src="docs/screenshots/quiz.png" width="200" /> </p> Crop the Fig 7.1–7.6 images from the project report, or export fresh ones from an emulator, and drop them into a docs/screenshots/ folder in this repo. -->

Screenshots coming soon — see docs/ for design references.

Getting Started
Prerequisites
Flutter SDK (stable channel, Dart ≥ 3.3.0)
A Firebase project with Authentication, Cloud Firestore, and Cloud Messaging enabled
Android Studio / VS Code with the Flutter and Dart extensions
Setup
bash
# Clone the repo
git clone https://github.com/Zaki003/deenroutine.git
cd deenroutine

# Install dependencies
flutter pub get

# Regenerate localization files (also runs automatically on build)
flutter gen-l10n

# Run on a connected device or emulator
flutter run

You'll need your own firebase_options.dart (generated via flutterfire configure) and a Firebase project configured to match the collections in firestore.rules and firestore.indexes.json.

Content management

Quiz questions and daily quotes are edited as JSON and pushed to Firestore via Node scripts — not through the app or Firebase console directly:

bash
npm install
npm run seed:quiz      # push data/quiz_questions.json → QuizQuestions
npm run seed:quotes    # push data/daily_quotes.json → DailyQuotes

See data/README.md for the one-time service account setup and content-format rules.

Useful commands
bash
flutter analyze     # static analysis
flutter test         # run tests
Roadmap
In-app + web-based account deletion (Play Store requirement)
iOS release and wider cross-device testing
Push notifications via FCM (beyond local scheduling)
Social/community habit challenges
AI-assisted habit recommendations
Richer analytics dashboard (weekly/monthly trends)
Academic Context

DeenRoutine began as a Project II thesis at the Institute of Information & Communication Technology (IICT), Shahjalal University of Science & Technology, submitted by Zaki Faiaz Chowdhury (MIT – 07 Batch), supervised by Dr. M. Abdullah Al Mumin. The full project report — covering requirements analysis, system design, and testing — is available in this repository.

License

No license selected yet — all rights reserved by default until one is added.

Contact

Built and maintained by Zaki Faiaz Chowdhury.
