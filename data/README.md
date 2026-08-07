# Quiz content

`quiz_questions.json` is the **single source of truth** for the app's quiz bank.
The app itself reads from the Firestore `QuizQuestions` collection — this file is
what you edit, and the seed script pushes it up.

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

One-time setup: Firebase console → Project settings → Service accounts →
*Generate new private key*, and save the download as
`scripts/serviceAccountKey.json`. That file is gitignored — never commit it.

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
