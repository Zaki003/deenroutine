/**
 * One-off clean-up: rounds the latitude/longitude stored on existing
 * `PrayerCache` documents to 2 decimal places (~1.1 km).
 *
 * Until commit 167ca82 the app wrote the device's full-precision GPS position
 * into these documents (and sent it to Aladhan), although the privacy policy
 * and onboarding promise coordinates are rounded to about 1 km first. Only the
 * document ID was rounded. PrayerCache is readable by any signed-in user, so
 * the precise values already stored need rounding too. New documents are
 * already written rounded.
 *
 * Usage (from the project root):
 *   node scripts/scrub_prayer_cache_coords.js           # dry run: report only, writes nothing
 *   node scripts/scrub_prayer_cache_coords.js --apply   # round the stored coordinates
 *
 * Safe to re-run: documents already rounded are skipped. Only the latitude and
 * longitude fields change; the cached prayer times, the document IDs and the
 * rest of each document are left as they are.
 *
 * Credentials: put your Firebase service account key at scripts/serviceAccountKey.json,
 * or set GOOGLE_APPLICATION_CREDENTIALS to its path.
 */

const fs = require('fs');
const path = require('path');
const { initializeApp, cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const COLLECTION = 'PrayerCache';
const KEY_FILE = path.join(__dirname, 'serviceAccountKey.json');
const BATCH_LIMIT = 500; // Firestore's per-batch write cap

const apply = process.argv.includes('--apply');

function initFirebase() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    initializeApp({ credential: applicationDefault() });
    return;
  }
  if (fs.existsSync(KEY_FILE)) {
    initializeApp({ credential: cert(require(KEY_FILE)) });
    return;
  }
  console.error(
    '\nError: No Firebase credentials found.\n' +
      '  In the Firebase console: Project settings > Service accounts > Generate new private key,\n' +
      `  then save the downloaded file as:\n    ${KEY_FILE}\n`
  );
  process.exit(1);
}

/** The same rounding the app uses: Dart's toStringAsFixed(2), parsed back. */
function round2(value) {
  return Number(value.toFixed(2));
}

async function main() {
  initFirebase();
  const db = getFirestore();
  const snap = await db.collection(COLLECTION).get();

  const updates = [];
  let alreadyRounded = 0;
  let noCoordinates = 0;
  for (const doc of snap.docs) {
    const { latitude, longitude } = doc.data();
    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      noCoordinates++;
      continue;
    }
    const lat = round2(latitude);
    const lng = round2(longitude);
    if (lat === latitude && lng === longitude) {
      alreadyRounded++;
      continue;
    }
    updates.push({ ref: doc.ref, lat, lng });
  }

  console.log(`\n${COLLECTION}: ${snap.size} document(s)`);
  console.log(`  already rounded:       ${alreadyRounded}`);
  console.log(`  without coordinates:   ${noCoordinates}`);
  console.log(`  need rounding:         ${updates.length}`);

  if (!updates.length) {
    console.log('\nNothing to do.\n');
    return;
  }
  if (!apply) {
    console.log('\nDry run - nothing was written. Re-run with --apply to round them.\n');
    return;
  }

  for (let i = 0; i < updates.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    for (const u of updates.slice(i, i + BATCH_LIMIT)) {
      batch.update(u.ref, { latitude: u.lat, longitude: u.lng });
    }
    await batch.commit();
  }
  console.log(`\nRounded the coordinates on ${updates.length} document(s).\n`);
}

main().catch((err) => {
  console.error(`\nError: ${err.message}\n`);
  process.exit(1);
});
