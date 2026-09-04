/**
 * One-off: seeds a handful of sample habits into a specific account, so the
 * Play Store reviewer/demo account doesn't land on an empty dashboard.
 *
 * Usage (from the project root):
 *   node scripts/seed_reviewer_habits.js <email>
 *
 * Credentials: scripts/serviceAccountKey.json (same as the other seed scripts).
 */

const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const KEY_FILE = path.join(__dirname, 'serviceAccountKey.json');
const email = process.argv[2];

if (!email) {
  console.error('Usage: node scripts/seed_reviewer_habits.js <email>');
  process.exit(1);
}

initializeApp({ credential: cert(require(KEY_FILE)) });
const db = getFirestore();
const auth = getAuth();

const now = Timestamp.now();

// A spread of tracking types so a reviewer sees the app's actual range of
// habit styles, not just a plain checkbox list. A couple carry today's
// progress so the dashboard doesn't read as freshly-created/empty.
const HABITS = [
  {
    title: 'Pray 5 times daily',
    category: 'islam',
    trackingType: 'checklist',
    checklistItems: ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
    todayChecklistDone: ['Fajr'],
    lastCompletedDate: now,
  },
  {
    title: 'Read Qur\'an pages',
    category: 'islam',
    trackingType: 'numeric',
    numericTarget: 4,
    numericUnit: 'pages',
    todayProgressValue: 2,
    lastCompletedDate: now,
  },
  {
    title: 'Exercise',
    category: 'lifestyle',
    trackingType: 'yesNo',
    completed: true,
    lastCompletedDate: now,
  },
  {
    title: 'Drink water',
    category: 'lifestyle',
    trackingType: 'numeric',
    numericTarget: 8,
    numericUnit: 'glasses',
    todayProgressValue: 5,
    lastCompletedDate: now,
  },
  {
    title: 'Avoid social media',
    category: 'lifestyle',
    trackingType: 'avoidance',
  },
];

async function main() {
  const user = await auth.getUserByEmail(email);
  const uid = user.uid;

  const batch = db.batch();
  for (const h of HABITS) {
    const ref = db.collection('Habits').doc();
    batch.set(ref, {
      uid,
      title: h.title,
      category: h.category,
      frequency: 'daily',
      completed: h.completed ?? false,
      lastCompletedDate: h.lastCompletedDate ?? null,
      selectedDays: [],
      reminderHour: null,
      reminderMinute: null,
      trackingType: h.trackingType,
      numericTarget: h.numericTarget ?? 1,
      numericUnit: h.numericUnit ?? '',
      timerTargetMinutes: h.timerTargetMinutes ?? 10,
      checklistItems: h.checklistItems ?? [],
      ratingScale: h.ratingScale ?? 5,
      todayProgressValue: h.todayProgressValue ?? 0,
      todayChecklistDone: h.todayChecklistDone ?? [],
      todayRatingValue: h.todayRatingValue ?? null,
      createdAt: now,
    });
  }
  await batch.commit();
  console.log(`Seeded ${HABITS.length} habits for ${email} (uid: ${uid})`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
