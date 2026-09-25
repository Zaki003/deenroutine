# Privacy Policy for DeenRoutine

**Effective date:** September 26, 2026

**Plain-English summary:** DeenRoutine stores your habits, prayer log, quiz scores, Learn progress, and account info (name + email) in a private database tied to your account. It uses your approximate location only to calculate accurate prayer times, never shows you ads, and never sells your data. Usage analytics are entirely optional and off unless you turn them on.

## 1. Overview

DeenRoutine ("the app," "we," "us") is a personal habit and spirituality tracker built by an independent developer. This policy explains what information the app collects when you use it, why, and how it's protected. It covers every feature currently in the app: account creation, habit tracking, prayer times and prayer tracking, the daily quote and saved favourites, the Islamic-knowledge quiz and Learn lessons, and notifications.

## 2. Information We Collect

- **Account information:** When you create an account, we collect your name, email address, and password, plus the avatar you pick. Your password is handled entirely by Firebase Authentication (a Google service) — DeenRoutine never sees or stores your password directly.
- **Habit data:** The habits you create (titles, category, frequency, reminder times) and your daily completion history, used to calculate streaks and show your progress.
- **Prayer log:** If you mark your prayers as prayed on the Prayer screen, a record of which of the five daily prayers you logged each day and whether each was on time, late, made up (qada), not prayed or excused. It's used to show your prayer insights on your profile. If you turn on prayer check-ins, tapping Prayed on the notification saves the same record. Only you can see it; it's never shared or used for analytics.
- **Quiz results:** Your scores and completion dates for the Islamic-knowledge quiz, so you can see your best score over time.
- **Learn progress:** Which Learn lessons and topic assessments you've completed, and your assessment scores.
- **Favourites:** The ayat and hadith you save as favourites (up to five), stored with your profile.
- **Approximate location:** With your permission, your device's approximate GPS coordinates — or, if you'd rather, a city you pick yourself — used only to calculate accurate prayer times for your area (see Section 4).
- **App preferences:** Your chosen theme (light/dark), language (English/Bangla), notification choices, prayer-time calculation method, and last location, stored locally on your device.
- **Usage analytics (optional, off by default):** If you turn this on in Settings → Preferences, DeenRoutine uses Firebase Analytics (a Google service) to record things like which screens you visit, that a habit was created and its category/tracking type, that a quiz was completed and roughly how well you scored, or that a streak reached a milestone. This never includes your habit titles, quiz answers, or anything else you typed — only which feature was used, in general shape.

We do not collect payment information, government ID numbers, contacts, photos, or browsing history. DeenRoutine has no advertising. Analytics are opt-in only — see Section 5.

## 3. How We Use Your Information

We use the information above only to run the app's own features:

- To create and secure your account, and let you log in from your device.
- To save and sync your habits, streaks, prayer log, quiz results, Learn progress, and favourites so they're there the next time you open the app.
- To calculate prayer times for your current location.
- To schedule notifications — habit reminders, the daily ayah or hadith, streak and weekly nudges, prayer-time adhan alarms, and prayer check-ins if you turn them on. These are scheduled entirely on your device and nothing about them is sent anywhere, except that tapping Prayed on a prayer check-in saves that prayer to your prayer log.

We do not sell, rent, or share your personal information with third parties for marketing purposes.

## 4. Location Data & Prayer Times

DeenRoutine asks for location permission so it can show correct prayer times for where you are:

- Your coordinates are rounded to roughly 1.1 km precision (2 decimal places) before being used.
- They're sent to [Aladhan](https://aladhan.com), a free public prayer-time calculation API, along with the date — nothing that identifies you personally.
- If you pick a city instead of using GPS, its coordinates are used the same way, and no GPS reading is taken.
- The result is cached in our database, keyed only by the rounded coordinates and date, so the app doesn't have to re-request the same day's times for the same area. This cache isn't tied to your account.

You can deny or revoke location permission at any time in Android's app settings; prayer times just won't be available until it's granted again.

## 5. Usage Analytics (Optional)

DeenRoutine does not collect usage analytics by default. If you turn it on — Settings → Preferences → Usage Analytics — the app uses Firebase Analytics (Google) to record:

- Which screens you visit.
- That a habit was created, with its category and tracking type — never its title.
- That a habit was completed, with its tracking type — never which one.
- That a quiz was completed, with question count and a rough score band — never your answers.
- That a streak reached a milestone (3/7/30/100/365 days) — never which habit.
- Which starter template you picked, if any.
- That you tapped a share button, and on which screen — never what was shared.

We use this only to see which features people actually use, so we can improve the app and design better default habit templates. It's never used to build an advertising profile, and we've turned off Google's data-sharing settings in our Firebase project, so this data isn't used by Google for its own purposes either.

Turn it on or off at any time in Settings → Preferences.

## 6. Third-Party Services

- **Firebase (Google)** — Authentication and Cloud Firestore database. Firebase stores your account info, habits, prayer log, quiz results, Learn progress, favourites, and cached prayer times. See [Google's Privacy Policy](https://policies.google.com/privacy).
- **Firebase Analytics (Google)** — only if you've turned on usage analytics; see Section 5.
- **Aladhan API** — receives approximate coordinates and a date to return prayer times. See their terms at aladhan.com.

We don't use Google/Facebook/Apple sign-in, so no login data is shared with those platforms — DeenRoutine accounts are email-and-password only.

## 7. Data Storage & Security

Your data is stored in Cloud Firestore and protected by security rules that restrict access so only you can read or write your own habits, logs, prayer log, quiz results, Learn progress, and profile — enforced on Google's servers, not just in the app. Data is encrypted in transit (HTTPS/TLS) and at rest by Firebase's infrastructure.

## 8. Data Retention

We retain your account and habit data for as long as your account exists. You can permanently delete your account and all associated data yourself, at any time, with no waiting period:

- **In the app:** go to Profile → Settings → Delete Account.
- **On the web, without installing the app:** visit [https://zaki003.github.io/deenroutine/delete-account.html](https://zaki003.github.io/deenroutine/delete-account.html) and follow the prompts.

Both options delete your data immediately and permanently — there is no 30-day grace period. If you can't use either option (for example, you're locked out of your account), email us (Section 12) and we'll delete it for you.

## 9. Your Rights & Choices

- You can edit or delete individual habits at any time within the app.
- You can permanently delete your entire account and all associated data yourself, instantly — either in the app (Profile → Settings → Delete Account) or on the web at [https://zaki003.github.io/deenroutine/delete-account.html](https://zaki003.github.io/deenroutine/delete-account.html), with no app install required. This cannot be undone.
- You can also request a copy of your data, or ask us to delete your account by hand, by emailing us at the address below — useful if you're unable to use either self-service option above.
- You can revoke location or notification permissions at any time from your device's system settings.
- You can turn usage analytics on or off at any time in Settings → Preferences.

## 10. Children's Privacy

DeenRoutine is not directed at children under 13, and we don't knowingly collect personal information from children under 13. If you believe a child has created an account, contact us and we'll delete it.

## 11. Changes to This Policy

If we make material changes to this policy, we'll update the effective date above. Continued use of the app after a change means you accept the revised policy.

## 12. Contact Us

Questions about this policy or your data? Email: **zakifchowdhury.dev@gmail.com**
