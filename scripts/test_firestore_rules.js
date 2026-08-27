/**
 * Rules tests for firestore.rules, run against the Firestore emulator —
 * never against the real project, so this needs no service account key.
 *
 * Usage (from the project root):
 *   npm run test:rules
 *
 * That runs `firebase emulators:exec`, which starts the Firestore emulator,
 * waits for this script to exit, then shuts the emulator down. Requires a
 * JVM on PATH (the emulator is Java-based) and the Firebase CLI.
 *
 * Focus is the HabitLogs owner-only rule specifically, since it's the one
 * that depends on data (a denormalized `uid` field) rather than just an auth
 * check, and the one CLAUDE.md's "Firestore rules aren't a post-filter" note
 * warns about: a query missing a `uid` clause fails for every caller, not
 * just for other users' data. Each check below sets up its own data as an
 * unauthenticated admin context, then asserts what an authenticated client
 * context may do — see the `assertSucceeds`/`assertFails` calls.
 *
 * Also covers the owner-delete rules on Users/QuizResults added for account
 * deletion (Play Store data-deletion requirement) — these are new enough
 * (no prior `delete` permission existed on either collection) that a wrong
 * rule could either silently break self-service deletion or, worse, let
 * one account delete another's profile/results.
 */

const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const OWNER_UID = 'owner-uid';
const OTHER_UID = 'other-uid';
const HABIT_ID = 'habit-1';
const LOG_ID = 'log-1';
const QUIZ_RESULT_ID = 'quiz-result-1';

const results = [];

async function check(name, fn) {
  try {
    await fn();
    results.push({ name, ok: true });
    console.log(`  ok — ${name}`);
  } catch (err) {
    results.push({ name, ok: false, err });
    console.log(`  FAIL — ${name}`);
    console.log(`    ${err.message}`);
  }
}

async function seedOwnerLog(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
    await adminCtx
      .firestore()
      .collection('HabitLogs')
      .doc(LOG_ID)
      .set({ habitId: HABIT_ID, uid: OWNER_UID, date: new Date(), status: true });
  });
}

async function seedOwnerUser(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
    await adminCtx
      .firestore()
      .collection('Users')
      .doc(OWNER_UID)
      .set({ name: 'Owner', email: 'owner@example.com', createdAt: new Date() });
  });
}

async function seedOwnerQuizResult(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
    await adminCtx
      .firestore()
      .collection('QuizResults')
      .doc(QUIZ_RESULT_ID)
      .set({ uid: OWNER_UID, score: 4, totalQuestions: 5, completedAt: new Date() });
  });
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: 'deenroutine-rules-test',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  await check('owner can get their own HabitLogs doc', async () => {
    await seedOwnerLog(testEnv);
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(owner.firestore().collection('HabitLogs').doc(LOG_ID).get());
  });

  await check('another authenticated user cannot get someone else\'s HabitLogs doc', async () => {
    await seedOwnerLog(testEnv);
    const other = testEnv.authenticatedContext(OTHER_UID);
    await assertFails(other.firestore().collection('HabitLogs').doc(LOG_ID).get());
  });

  await check('an unauthenticated client cannot get a HabitLogs doc', async () => {
    await seedOwnerLog(testEnv);
    const anon = testEnv.unauthenticatedContext();
    await assertFails(anon.firestore().collection('HabitLogs').doc(LOG_ID).get());
  });

  await check('owner can list their own logs when the query filters by uid', async () => {
    await seedOwnerLog(testEnv);
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .collection('HabitLogs')
        .where('uid', '==', OWNER_UID)
        .where('habitId', '==', HABIT_ID)
        .get()
    );
  });

  await check(
    'a habitId-only query (no uid clause) is rejected outright, even for the owner — ' +
      'this is the bug FirestoreService.watchHabitLogs used to have',
    async () => {
      await seedOwnerLog(testEnv);
      const owner = testEnv.authenticatedContext(OWNER_UID);
      await assertFails(
        owner.firestore().collection('HabitLogs').where('habitId', '==', HABIT_ID).get()
      );
    }
  );

  await check('creating a HabitLogs doc with the caller\'s own uid is allowed', async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .collection('HabitLogs')
        .doc('new-log')
        .set({ habitId: HABIT_ID, uid: OWNER_UID, date: new Date(), status: true })
    );
  });

  await check('creating a HabitLogs doc stamped with someone else\'s uid is denied', async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .collection('HabitLogs')
        .doc('spoofed-log')
        .set({ habitId: HABIT_ID, uid: OTHER_UID, date: new Date(), status: true })
    );
  });

  await check('owner can delete their own Users doc', async () => {
    await seedOwnerUser(testEnv);
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(owner.firestore().collection('Users').doc(OWNER_UID).delete());
  });

  await check('another authenticated user cannot delete someone else\'s Users doc', async () => {
    await seedOwnerUser(testEnv);
    const other = testEnv.authenticatedContext(OTHER_UID);
    await assertFails(other.firestore().collection('Users').doc(OWNER_UID).delete());
  });

  await check('owner can delete their own QuizResults doc', async () => {
    await seedOwnerQuizResult(testEnv);
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(owner.firestore().collection('QuizResults').doc(QUIZ_RESULT_ID).delete());
  });

  await check('another authenticated user cannot delete someone else\'s QuizResults doc', async () => {
    await seedOwnerQuizResult(testEnv);
    const other = testEnv.authenticatedContext(OTHER_UID);
    await assertFails(other.firestore().collection('QuizResults').doc(QUIZ_RESULT_ID).delete());
  });

  await testEnv.cleanup();

  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length}/${results.length} passed.`);
  if (failed.length) {
    console.log('\nFailing checks need a real fix before this suite is trustworthy.');
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('\nCouldn\'t run the rules tests:', err.message);
  console.error(
    'Is a JVM on PATH? The Firestore emulator needs Java. ' +
      'Run `firebase emulators:exec --only firestore "node scripts/test_firestore_rules.js"` directly for more detail.'
  );
  process.exit(1);
});
