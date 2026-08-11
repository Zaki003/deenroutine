/**
 * Syncs data/daily_quotes.json into the Firestore `DailyQuotes` collection.
 *
 * Usage (from the project root):
 *   node scripts/seed_daily_quotes.js            # add + update
 *   node scripts/seed_daily_quotes.js --prune    # also delete quotes removed from the file
 *   node scripts/seed_daily_quotes.js --dry-run  # validate + show a plan, write nothing
 *
 * Credentials: put your Firebase service account key at scripts/serviceAccountKey.json,
 * or set GOOGLE_APPLICATION_CREDENTIALS to its path.
 *
 * The `id` field in the JSON becomes the Firestore document id, so re-running this
 * script updates existing quotes in place instead of creating duplicates.
 */

const fs = require('fs');
const path = require('path');
// firebase-admin v14 dropped the old `admin.credential` / `admin.firestore()`
// namespaces, so everything comes from the modular subpath entry points.
const { initializeApp, cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const COLLECTION = 'DailyQuotes';
const DATA_FILE = path.join(__dirname, '..', 'data', 'daily_quotes.json');
const KEY_FILE = path.join(__dirname, 'serviceAccountKey.json');

const prune = process.argv.includes('--prune');
const dryRun = process.argv.includes('--dry-run');

function loadQuotes() {
  if (!fs.existsSync(DATA_FILE)) {
    fail(`Data file not found: ${DATA_FILE}`);
  }

  let raw;
  try {
    raw = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  } catch (err) {
    fail(`${DATA_FILE} is not valid JSON.\n  ${err.message}`);
  }

  if (!Array.isArray(raw)) fail('The data file must contain a JSON array of quotes.');

  const errors = [];
  const seen = new Set();

  raw.forEach((q, i) => {
    const where = `quote #${i + 1}${q && q.id ? ` (id "${q.id}")` : ''}`;

    if (!q || typeof q !== 'object') return errors.push(`${where}: not an object.`);
    if (!q.id || typeof q.id !== 'string') return errors.push(`${where}: missing a string "id".`);
    if (seen.has(q.id)) errors.push(`${where}: duplicate id.`);
    seen.add(q.id);

    if (!q.text || typeof q.text !== 'string' || !q.text.trim()) {
      errors.push(`${where}: missing "text".`);
    }
    // The source is the citation shown under the quote — an unattributed verse
    // or hadith is exactly what this collection must never serve.
    if (!q.source || typeof q.source !== 'string' || !q.source.trim()) {
      errors.push(`${where}: missing "source" (the verse or hadith reference).`);
    }
    if (!q.category || typeof q.category !== 'string' || !q.category.trim()) {
      errors.push(`${where}: missing "category".`);
    }
    // Bangla translation is optional — the app falls back to English text
    // until a translation is added — but if present it must be a string.
    if (q.textBn !== undefined && typeof q.textBn !== 'string') {
      errors.push(`${where}: "textBn" must be a string if present.`);
    }
  });

  if (errors.length) {
    console.error(`\n${errors.length} problem(s) found in data/daily_quotes.json:\n`);
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

/// FNV-1a. Any stable string->number hash works here; this one is short.
function hash(str) {
  let h = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h;
}

/**
 * Assigns each quote the `dayIndex` the app looks up: quote N is shown on every
 * day whose day-number mod the collection size equals N.
 *
 * The file lists all the Qur'an verses first and then the hadith, which would
 * otherwise mean two months of verses followed by two months of hadith. Ordering
 * by a hash of the id interleaves the two. The hash is used rather than a shuffle
 * because it must be *stable*: re-running this script has to leave every quote on
 * the same day, or today's quote would change under the user's feet on each sync.
 */
function withDayIndexes(quotes) {
  return quotes
    .slice()
    .sort((a, b) => hash(a.id) - hash(b.id) || a.id.localeCompare(b.id))
    .map((q, i) => ({ ...q, dayIndex: i }));
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
  const quotes = loadQuotes();
  console.log(`Validated ${quotes.length} quotes in data/daily_quotes.json.`);

  initFirebase();
  const db = getFirestore();

  const existing = await db.collection(COLLECTION).get();
  const existingIds = new Set(existing.docs.map((d) => d.id));
  const fileIds = new Set(quotes.map((q) => q.id));

  const added = quotes.filter((q) => !existingIds.has(q.id));
  const stale = existing.docs.filter((d) => !fileIds.has(d.id));

  console.log(
    `Firestore has ${existing.size} quote(s): ` +
      `${added.length} to add, ${quotes.length - added.length} to update, ` +
      `${stale.length} in Firestore but not in the file.`
  );

  // A stale doc that still carries a dayIndex from an earlier seed collides with
  // a seeded one and makes that day's lookup ambiguous, so it has to go. A doc
  // added by hand has no dayIndex at all: the app's equality query can never
  // match it, so it sits dormant and is left alone unless --prune is asked for.
  const colliding = stale.filter((d) => typeof d.data().dayIndex === 'number');
  const dormant = stale.filter((d) => typeof d.data().dayIndex !== 'number');

  if (colliding.length && !prune && !dryRun) {
    fail(
      `${colliding.length} quote(s) hold a dayIndex but are no longer in data/daily_quotes.json:\n` +
        `    ${colliding.map((d) => d.id).join(', ')}\n` +
        '  They would collide with the seeded rotation.\n' +
        '  Re-run with --prune to delete them, or add them back to the data file.'
    );
  }

  if (dryRun) {
    if (added.length) console.log(`  would add:    ${added.map((q) => q.id).join(', ')}`);
    if (colliding.length) {
      console.log(
        `  ${prune ? 'would delete:' : 'would block on:'} ${colliding.map((d) => d.id).join(', ')}`
      );
    }
    if (dormant.length) {
      console.log(
        `  ${prune ? 'would delete:' : 'would leave:  '} ${dormant.map((d) => d.id).join(', ')}` +
          ' (no dayIndex — never shown)'
      );
    }
    console.log('\nDry run — nothing written.\n');
    return;
  }

  const toDelete = prune ? stale : colliding;
  if (toDelete.length) {
    await commitInBatches(db, toDelete, (batch, doc) => batch.delete(doc.ref));
    console.log(`Deleted ${toDelete.length} quote(s) no longer in the file.`);
  }
  if (!prune && dormant.length) {
    console.log(
      `Left ${dormant.length} quote(s) that have no dayIndex — they are never shown. ` +
        'Re-run with --prune to delete them.'
    );
  }

  await commitInBatches(db, withDayIndexes(quotes), (batch, q) => {
    batch.set(db.collection(COLLECTION).doc(q.id), {
      text: q.text,
      source: q.source,
      category: q.category,
      textBn: q.textBn || '',
      dayIndex: q.dayIndex,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  console.log(`Wrote ${quotes.length} quote(s) to ${COLLECTION}.`);

  console.log('\nDone.\n');
}

main().catch((err) => fail(err.stack || err.message));
