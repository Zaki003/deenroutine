# Privacy Policy for DeenRoutine

**Effective date:** August 15, 2026

**Plain-English summary:** DeenRoutine stores your habits, quiz scores, and account info (name + email) in a private database tied to your account. It uses your approximate location only to calculate accurate prayer times, and never sells your data or shows you ads.

## 1. Overview

DeenRoutine ("the app," "we," "us") is a personal habit and spirituality tracker built by an independent developer. This policy explains what information the app collects when you use it, why, and how it's protected. It covers every feature currently in the app: account creation, habit tracking, prayer times, the daily quote, the Islamic-knowledge quiz, and reminder notifications.

## 2. Information We Collect

- **Account information:** When you create an account, we collect your name, email address, and password. Your password is handled entirely by Firebase Authentication (a Google service) — DeenRoutine never sees or stores your password directly.
- **Habit data:** The habits you create (titles, category, frequency, reminder times) and your daily completion history, used to calculate streaks and show your progress.
- **Quiz results:** Your scores and completion dates for the Islamic-knowledge quiz, so you can see your best score over time.
- **Approximate location:** With your permission, your device's approximate GPS coordinates, used only to calculate accurate prayer times for your area (see Section 4).
- **App preferences:** Your chosen theme (light/dark) and language (English/Bangla), stored locally on your device.

We do not collect payment information, government ID numbers, contacts, photos, or browsing history. DeenRoutine has no advertising and no analytics or tracking SDKs.

## 3. How We Use Your Information

We use the information above only to run the app's own features:

- To create and secure your account, and let you log in from your device.
- To save and sync your habits, streaks, and quiz results so they're there the next time you open the app.
- To calculate prayer times for your current location.
- To schedule the habit reminder notifications you set — these are scheduled entirely on your device and never leave it.

We do not sell, rent, or share your personal information with third parties for marketing purposes.

## 4. Location Data & Prayer Times

DeenRoutine asks for location permission so it can show correct prayer times for where you are:

- Your coordinates are rounded to roughly 1.1 km precision (2 decimal places) before being used.
- They're sent to [Aladhan](https://aladhan.com), a free public prayer-time calculation API, along with the date — nothing that identifies you personally.
- The result is cached in our database, keyed only by the rounded coordinates and date, so the app doesn't have to re-request the same day's times for the same area. This cache isn't tied to your account.

You can deny or revoke location permission at any time in Android's app settings; prayer times just won't be available until it's granted again.

## 5. Third-Party Services

- **Firebase (Google)** — Authentication and Cloud Firestore database. Firebase stores your account info, habits, quiz results, and cached prayer times. See [Google's Privacy Policy](https://policies.google.com/privacy).
- **Aladhan API** — receives approximate coordinates and a date to return prayer times. See their terms at aladhan.com.

We don't use Google/Facebook/Apple sign-in, so no login data is shared with those platforms — DeenRoutine accounts are email-and-password only.

## 6. Data Storage & Security

Your data is stored in Cloud Firestore and protected by security rules that restrict access so only you can read or write your own habits, logs, quiz results, and profile — enforced on Google's servers, not just in the app. Data is encrypted in transit (HTTPS/TLS) and at rest by Firebase's infrastructure.

## 7. Data Retention

We retain your account and habit data for as long as your account exists. If you'd like your account and associated data deleted, contact us (Section 11) and we'll delete it within 30 days.

## 8. Children's Privacy

DeenRoutine is not directed at children under 13, and we don't knowingly collect personal information from children under 13. If you believe a child has created an account, contact us and we'll delete it.

## 9. Your Rights & Choices

- You can edit or delete individual habits at any time within the app.
- You can request a copy of your data, or request that your account and all associated data be permanently deleted, by emailing us at the address below.
- You can revoke location or notification permissions at any time from your device's system settings.

## 10. Changes to This Policy

If we make material changes to this policy, we'll update the effective date above. Continued use of the app after a change means you accept the revised policy.

## 11. Contact Us

Questions about this policy or your data? Email: **zakifaiazchy@gmail.com**
