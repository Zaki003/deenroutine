/**
 * Syncs data/quiz_questions.json into the Firestore `QuizQuestions` collection.
 *
 * Usage (from the project root):
 *   node scripts/seed_quiz_questions.js            # add + update
 *   node scripts/seed_quiz_questions.js --prune    # also delete questions removed from the file
 *   node scripts/seed_quiz_questions.js --dry-run  # validate + show a plan, write nothing
 *
 * Credentials: put your Firebase service account key at scripts/serviceAccountKey.json,
 * or set GOOGLE_APPLICATION_CREDENTIALS to its path.
 *
 * The `id` field in the JSON becomes the Firestore document id, so re-running this
 * script updates existing questions in place instead of creating duplicates.
 */

const fs = require('fs');
const path = require('path');
// firebase-admin v14 dropped the old `admin.credential` / `admin.firestore()`
// namespaces, so everything comes from the modular subpath entry points.
const { initializeApp, cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const COLLECTION = 'QuizQuestions';
const DATA_FILE = path.join(__dirname, '..', 'data', 'quiz_questions.json');
const KEY_FILE = path.join(__dirname, 'serviceAccountKey.json');

const prune = process.argv.includes('--prune');
const dryRun = process.argv.includes('--dry-run');

function loadQuestions() {
  if (!fs.existsSync(DATA_FILE)) {
    fail(`Data file not found: ${DATA_FILE}`);
  }

  let raw;
  try {
    raw = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  } catch (err) {
    fail(`${DATA_FILE} is not valid JSON.\n  ${err.message}`);
  }

  if (!Array.isArray(raw)) fail('The data file must contain a JSON array of questions.');

  const errors = [];
  const seen = new Set();

  raw.forEach((q, i) => {
    const where = `question #${i + 1}${q && q.id ? ` (id "${q.id}")` : ''}`;

    if (!q || typeof q !== 'object') return errors.push(`${where}: not an object.`);
    if (!q.id || typeof q.id !== 'string') return errors.push(`${where}: missing a string "id".`);
    if (seen.has(q.id)) errors.push(`${where}: duplicate id.`);
    seen.add(q.id);

    if (!q.question || typeof q.question !== 'string') {
      errors.push(`${where}: missing "question" text.`);
    }
    if (!Array.isArray(q.options) || q.options.length < 2) {
      errors.push(`${where}: needs at least 2 "options".`);
      return;
    }
    if (q.options.some((o) => typeof o !== 'string' || !o.trim())) {
      errors.push(`${where}: every option must be a non-empty string.`);
    }
    if (new Set(q.options).size !== q.options.length) {
      errors.push(`${where}: options must be unique (the app matches answers by text).`);
    }
    if (!q.options.includes(q.answer)) {
      errors.push(
        `${where}: "answer" must exactly match one of the options.\n` +
          `      answer:  ${JSON.stringify(q.answer)}\n` +
          `      options: ${JSON.stringify(q.options)}`
      );
    }
    // Bangla translations are optional — the app falls back to the English
    // question/options until translations are added — but if given, options
    // must translate 1:1 with "options" so the app can match them by index.
    if (q.questionBn !== undefined && (typeof q.questionBn !== 'string' || !q.questionBn.trim())) {
      errors.push(`${where}: "questionBn" must be a non-empty string if present.`);
    }
    if (q.optionsBn !== undefined) {
      if (!Array.isArray(q.optionsBn) || q.optionsBn.length !== q.options.length) {
        errors.push(`${where}: "optionsBn" must have exactly as many entries as "options".`);
      } else if (q.optionsBn.some((o) => typeof o !== 'string' || !o.trim())) {
        errors.push(`${where}: every "optionsBn" entry must be a non-empty string.`);
      }
    }
  });

  if (errors.length) {
    console.error(`\n${errors.length} problem(s) found in data/quiz_questions.json:\n`);
    errors.forEach((e) => console.error(`  - ${e}`));
    console.error('\nNothing was written. Fix the file and run again.\n');
    process.exit(1);
  }

  return raw;
}

function initFirebase() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    initializeApp({ credential: applicationDefault() });
    return;
  }
  if (fs.existsSync(KEY_FILE)) {
    initializeApp({ credential: cert(require(KEY_FILE)) });
    return;
  }
  fail(
    'No Firebase credentials found.\n' +
      '  In the Firebase console: Project settings > Service accounts > Generate new private key,\n' +
      `  then save the downloaded file as:\n    ${KEY_FILE}`
  );
}

function fail(message) {
  console.error(`\nError: ${message}\n`);
  process.exit(1);
}

/// Fisher-Yates, returning a new array.
function shuffled(items) {
  const out = items.slice();
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

/// Shuffles `options` and applies the same permutation to `optionsBn`, so a
/// Bangla translation stays aligned with its English option by index (the
/// app matches `correctAnswer` against `options`, then reads the same index
/// out of `optionsBn` for display).
function shuffledOptionsPaired(options, optionsBn) {
  const order = shuffled(options.map((_, i) => i));
  return {
    options: order.map((i) => options[i]),
    optionsBn: optionsBn && optionsBn.length === options.length ? order.map((i) => optionsBn[i]) : [],
  };
}

/**
 * Assigns each question a `random` value that the app samples against.
 *
 * The questions are shuffled, then handed values spaced evenly across
 * [0, 1). Even spacing is what makes the app's `random >= pivot` cursor
 * query draw every question with equal probability — with unevenly
 * distributed values, questions that follow a large gap get picked far more
 * often than the rest.
 */
function withRandomKeys(questions) {
  const order = shuffled(questions);
  return order.map((q, i) => ({ ...q, random: (i + 0.5) / order.length }));
}

/// Commits writes in chunks, since a Firestore batch caps at 500 operations.
async function commitInBatches(db, items, apply) {
  const CHUNK = 400;
  for (let i = 0; i < items.length; i += CHUNK) {
    const batch = db.batch();
    items.slice(i, i + CHUNK).forEach((item) => apply(batch, item));
    await batch.commit();
  }
}

async function main() {
  const questions = loadQuestions();
  console.log(`Validated ${questions.length} questions in data/quiz_questions.json.`);

  initFirebase();
  const db = getFirestore();

  const existing = await db.collection(COLLECTION).get();
  const existingIds = new Set(existing.docs.map((d) => d.id));
  const fileIds = new Set(questions.map((q) => q.id));

  const added = questions.filter((q) => !existingIds.has(q.id));
  const stale = existing.docs.filter((d) => !fileIds.has(d.id));

  console.log(
    `Firestore has ${existing.size} question(s): ` +
      `${added.length} to add, ${questions.length - added.length} to update, ` +
      `${stale.length} in Firestore but not in the file.`
  );

  if (dryRun) {
    if (added.length) console.log(`  would add:    ${added.map((q) => q.id).join(', ')}`);
    if (stale.length) {
      console.log(
        `  ${prune ? 'would delete:' : 'would leave:  '} ${stale.map((d) => d.id).join(', ')}`
      );
    }
    console.log('\nDry run — nothing written.\n');
    return;
  }

  await commitInBatches(db, withRandomKeys(questions), (batch, q) => {
    // Stored shuffled so the answer isn't sitting in the same slot for
    // every question. The app reshuffles again on each attempt. optionsBn
    // is shuffled the same way so it stays aligned by index with options.
    const { options, optionsBn } = shuffledOptionsPaired(q.options, q.optionsBn);
    batch.set(db.collection(COLLECTION).doc(q.id), {
      questionText: q.question,
      options,
      correctAnswer: q.answer,
      category: q.category ?? 'General',
      random: q.random,
      questionTextBn: q.questionBn || '',
      optionsBn,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  console.log(`Wrote ${questions.length} question(s) to ${COLLECTION}.`);

  if (stale.length) {
    if (prune) {
      await commitInBatches(db, stale, (batch, doc) => batch.delete(doc.ref));
      console.log(`Deleted ${stale.length} question(s) no longer in the file.`);
    } else {
      console.log(
        `Left ${stale.length} extra question(s) in Firestore. ` +
          'Re-run with --prune to delete them.'
      );
    }
  }

  console.log('\nDone.\n');
}

main().catch((err) => fail(err.stack || err.message));
