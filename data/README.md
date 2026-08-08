# App content

Two datasets live here, each the **single source of truth** for a Firestore
collection. The app reads Firestore; these files are what you edit, and the seed
scripts push them up.

| File | Collection | Seed command |
| --- | --- | --- |
| `quiz_questions.json` | `QuizQuestions` | `npm run seed:quiz` |
| `daily_quotes.json` | `DailyQuotes` | `npm run seed:quotes` |

One-time setup for either: Firebase console → Project settings → Service
accounts → *Generate new private key*, and save the download as
`scripts/serviceAccountKey.json`. That file grants full admin access to the
project — it's gitignored, never commit it.

# Quiz content

`quiz_questions.json` is the quiz bank.

## Editing

Each entry looks like this:

```json
{
  "id": "q001",
  "category": "Quran",
  "question": "How many surahs are there in the Quran?",
  "options": ["114", "110", "120", "99"],
  "answer": "114"
}
```

Rules the script enforces before it writes anything:

- `id` must be unique and should **never change** — it's the Firestore document
  id, so a stable id means edits update the same question instead of creating a
  duplicate. New questions just need a new id (`q115`, `q116`, …).
- `answer` must be **character-for-character identical** to one of the `options`.
  The app compares answers by text, so a trailing space breaks the question.
- `options` must be unique, and there must be at least 2 of them.
- `category` is free-form. It's stored in Firestore for future filtering; the
  app currently ignores it.

## Pushing to Firestore

```bash
npm run seed:quiz:check   # validate + preview, writes nothing
npm run seed:quiz         # add new questions, update changed ones
npm run seed:quiz:prune   # same, and delete questions you removed from the file
```

Re-running is safe and idempotent. Without `--prune`, deleting a question from
this file leaves it in Firestore (so the app keeps serving it) — use
`seed:quiz:prune` when you actually want it gone.

## Two fields the script adds for you

Alongside your content, each document gets:

- `options` **shuffled**, so the answer isn't parked in the same slot for every
  question. The app shuffles again on each attempt, so write the options in
  whatever order is easiest to read.
- `random`, a value spaced evenly across `[0, 1)`. The app draws questions with
  a `random >= pivot` cursor query, so a 5-question quiz reads 5 documents
  instead of the whole bank. Even spacing is what makes every question equally
  likely to be drawn.

**Because of `random`, don't add questions by hand in the Firebase console.** A
document without a `random` value is invisible to the sampling query, so the app
will never show it. Add it to this file and re-run the script instead.

# Daily quotes

`daily_quotes.json` is the rotation shown on the dashboard — Qur'anic verses and
authentic hadith. Each entry looks like this:

```json
{
  "id": "dq001",
  "text": "So remember Me; I will remember you...",
  "source": "Qur'an 2:152",
  "category": "Remembrance"
}
```

- `id` must be unique and should **never change** (same reasoning as `q001`).
- `source` is required — it's the citation printed under the quote, and an
  unattributed verse or hadith is the one thing this collection must never serve.
  Use `Qur'an <surah>:<ayah>` or the collection and number
  (`Sahih al-Bukhari 6464`). Where a hadith is outside the two Sahihs, the grading
  is noted in the source string.
- `category` is the theme (Prayer, Gratitude, Patience …). Stored for future
  filtering; the app currently ignores it.

## How the daily rotation works

The script adds a `dayIndex` (0…n-1) to each document. The app computes
`days since 2026-01-01 (UTC) % collection size` and fetches the one document with
that index, so:

- **Everyone sees the same quote on the same day.** The day number is counted in
  **UTC** — using each device's local date would show users in Sydney and Los
  Angeles different quotes at the same moment.
- The dashboard costs one count + one document read, not a download of the bank.
- With 120 quotes the cycle repeats every 120 days.

`dayIndex` is assigned by ordering on a hash of the `id`, not by shuffling. That
keeps it **stable**: re-running the script leaves every quote on the same day
rather than changing today's quote under the user's feet. It also interleaves the
verses and hadith, which are grouped separately in the file.

```bash
npm run seed:quotes:check   # validate + preview, writes nothing
npm run seed:quotes         # add, update, and renumber
npm run seed:quotes:prune   # same, and delete quotes you removed from the file
```

Adding or removing a quote renumbers the whole rotation, which shifts what shows
on a given date. That's expected — the guarantee is that all users see the same
quote as each other, not that a given date keeps the same quote forever.

**Don't add quotes by hand in the Firebase console.** A document with no
`dayIndex` can never match the day's lookup, so the app will never show it. The
seed script reports these and leaves them alone; `--prune` deletes them.
