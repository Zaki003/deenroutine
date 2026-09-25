import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/learn_progress.dart';
import '../models/prayer_log.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../models/daily_quote.dart';
import '../utils/daily_quote_schedule.dart';

/// FR-04 / FR-05 / FR-06 / FR-09 / FR-10 / FR-11 / FR-12, plus account
/// deletion for the Play Store data-deletion requirement.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Random _random = Random();

  // ---------------- Habits (FR-04) ----------------
  Future<void> addHabit(Habit habit) {
    return _db.collection('Habits').doc(habit.habitId).set(habit.toMap());
  }

  Future<void> updateHabit(Habit habit) {
    return _db.collection('Habits').doc(habit.habitId).update(habit.toMap());
  }

  /// Deletes the habit and its full HabitLogs history together — the
  /// delete-habit confirmation promises the history goes with it, and
  /// leaving it behind would strand data still tagged with the user's uid
  /// that no UI can ever show again.
  Future<void> deleteHabit(Habit habit) async {
    await _db.collection('Habits').doc(habit.habitId).delete();
    await _deleteQueryInChunks(
      _db
          .collection('HabitLogs')
          .where('uid', isEqualTo: habit.uid)
          .where('habitId', isEqualTo: habit.habitId),
    );
  }

  Stream<List<Habit>> watchHabits(String uid) {
    return _db
        .collection('Habits')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Habit.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Habit completion + logs (FR-05, FR-11) ----------------

  /// Writes today's progress for [habit]: updates the Habits doc's
  /// denormalized completed/lastCompletedDate/todayProgressValue fields and
  /// upserts today's HabitLogs doc, atomically. [status] is the
  /// caller-computed "did today satisfy the habit" decision — this method
  /// does no target/scale comparison itself.
  Future<void> logProgress(
    Habit habit, {
    required bool status,
    int? numericValue,
    int? timerElapsedSeconds,
    List<String>? checklistDone,
    int? ratingValue,
  }) async {
    final batch = _db.batch();

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final habitRef = _db.collection('Habits').doc(habit.habitId);
    batch.update(habitRef, {
      'completed': status,
      'lastCompletedDate': Timestamp.fromDate(todayMidnight),
      'todayProgressValue': numericValue ?? timerElapsedSeconds ?? 0,
      'todayChecklistDone': checklistDone ?? [],
      'todayRatingValue': ratingValue,
    });

    final logId = '${habit.habitId}_${today.year}-${today.month}-${today.day}';
    final logRef = _db.collection('HabitLogs').doc(logId);
    final log = HabitLog(
      logId: logId,
      habitId: habit.habitId,
      uid: habit.uid,
      date: todayMidnight,
      status: status,
      numericValue: numericValue,
      timerElapsedSeconds: timerElapsedSeconds,
      checklistDone: checklistDone,
      ratingValue: ratingValue,
    );
    batch.set(logRef, log.toMap());

    await batch.commit();
  }

  /// [uid] must match the caller's own auth uid — Firestore rejects a list
  /// query outright (not a silent per-doc filter) unless every field the
  /// security rule checks is also pinned by an equality clause in the query
  /// itself, so this can't be scoped by [habitId] alone under the owner-only
  /// HabitLogs rule.
  Stream<List<HabitLog>> watchHabitLogs(String uid, String habitId) {
    return _db
        .collection('HabitLogs')
        .where('uid', isEqualTo: uid)
        .where('habitId', isEqualTo: habitId)
        .orderBy('date', descending: true)
        .limit(60)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HabitLog.fromMap(d.id, d.data())).toList());
  }

  /// Computes a simple consecutive-day streak from recent logs. A
  /// [HabitFrequency.specificDays] habit only counts its scheduled weekdays
  /// toward "consecutive" — a day it was never due is skipped rather than
  /// treated as a miss.
  ///
  /// [trackingType] flips the meaning of "a day succeeded" for
  /// [HabitTrackingType.avoidance]: every other type succeeds when a log
  /// says so (`status == true`); avoidance succeeds on *silence* — a slip is
  /// the only thing ever logged for it, so a day with no log at all is the
  /// win, and a logged day is the break.
  ///
  /// [today] is the reference day the walk starts from, defaulting to now -
  /// overridden to ask what the streak will read on a day that hasn't
  /// happened yet.
  int calculateStreak(
    List<HabitLog> logs, {
    required DateTime createdAt,
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> selectedDays = const [],
    HabitTrackingType trackingType = HabitTrackingType.yesNo,
    DateTime? today,
  }) {
    final createdMidnight = DateTime(createdAt.year, createdAt.month, createdAt.day);
    bool isScheduled(DateTime day) =>
        frequency != HabitFrequency.specificDays || selectedDays.contains(day.weekday % 7);

    final byDate = {
      for (final l in logs) DateTime(l.date.year, l.date.month, l.date.day): l.status,
    };
    bool daySucceeded(DateTime day) => trackingType == HabitTrackingType.avoidance
        ? !byDate.containsKey(day)
        : byDate[day] == true;

    int streak = 0;
    DateTime cursor = today ?? DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    // Not having done today's habit yet doesn't break an in-progress streak —
    // only a fully missed scheduled day does. Skip today, without breaking
    // anything, whenever it isn't itself a completed scheduled day;
    // otherwise start the walk from yesterday so the streak still shows.
    // Avoidance has no "not yet logged" ambiguity (silence already reads as
    // success), so it only needs the schedule check here, not daySucceeded.
    final skipToday = trackingType == HabitTrackingType.avoidance
        ? !isScheduled(cursor)
        : (!isScheduled(cursor) || !daySucceeded(cursor));
    if (skipToday) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Also bounded at 400 iterations beyond the createdAt cutoff below, so a
    // corrupt/empty selectedDays (never produced by the app's own day
    // picker, but not guaranteed for data edited directly in Firestore)
    // can't spin forever.
    for (var i = 0; i < 400; i++) {
      // A habit can't have a streak from before it existed. Without this,
      // an avoidance habit with zero logs — true of every avoidance habit
      // right after creation, since silence reads as success — would walk
      // all the way back to the 400-iteration cap instead of stopping at 0.
      if (cursor.isBefore(createdMidnight)) break;
      if (!isScheduled(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (!daySucceeded(cursor)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Completion for the current Mon–Sun week, one bool per day in that
  /// order. Used by the Habits screen's week-picker; days after today are
  /// simply not-yet-done rather than distinguished as "future".
  ///
  /// For [HabitTrackingType.avoidance] (see [calculateStreak]), a day with
  /// no log reads as a success — except a day later in the current week
  /// that hasn't happened yet, which must still read as not-done rather
  /// than a false "success" just because nothing's been logged for it.
  List<bool> weekCompletion(
    List<HabitLog> logs, {
    HabitTrackingType trackingType = HabitTrackingType.yesNo,
  }) {
    final byDate = {
      for (final l in logs) DateTime(l.date.year, l.date.month, l.date.day): l.status,
    };
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    // DateTime.weekday is 1=Mon..7=Sun.
    final monday = todayMidnight.subtract(Duration(days: todayMidnight.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      if (trackingType == HabitTrackingType.avoidance) {
        return !day.isAfter(todayMidnight) && !byDate.containsKey(day);
      }
      return byDate[day] == true;
    });
  }

  // ---------------- Daily motivation (FR-09) ----------------

  /// The quote of the day, identical for every user.
  ///
  /// `scripts/seed_daily_quotes.js` numbers the quotes `dayIndex` 0..n-1, so the
  /// day's quote is a single lookup rather than a download of the collection.
  /// See [quoteDayIndex] for how the day maps to an index.
  Future<DailyQuote?> getDailyQuote() async {
    final col = _db.collection('DailyQuotes');

    final total = (await col.count().get()).count ?? 0;
    if (total == 0) return null;

    final index = quoteDayIndex(DateTime.now(), total);

    final snap = await col.where('dayIndex', isEqualTo: index).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return DailyQuote.fromMap(snap.docs.first.id, snap.docs.first.data());
    }

    // No document claims today's index — the collection was edited by hand, or a
    // seed was interrupted. Fall back to the lowest index rather than showing
    // nothing; the next seed run renumbers everything and repairs the gap.
    final fallback = await col.orderBy('dayIndex').limit(1).get();
    if (fallback.docs.isEmpty) return null;
    return DailyQuote.fromMap(fallback.docs.first.id, fallback.docs.first.data());
  }

  /// The quote the dashboard will be showing at each of [instants], in the
  /// same order - null where no document claims that day's index. Lets the
  /// notification scheduler bake in a week of quotes with one query
  /// (a single-field `whereIn` needs no composite index).
  Future<List<DailyQuote?>> getDailyQuotesFor(List<DateTime> instants) async {
    final col = _db.collection('DailyQuotes');

    final total = (await col.count().get()).count ?? 0;
    if (total == 0) return List.filled(instants.length, null);

    final indexes = [for (final t in instants) quoteDayIndex(t, total)];
    final snap =
        await col.where('dayIndex', whereIn: indexes.toSet().toList()).get();
    final byIndex = {
      for (final d in snap.docs)
        (d.data()['dayIndex'] as num).toInt():
            DailyQuote.fromMap(d.id, d.data()),
    };
    return [for (final i in indexes) byIndex[i]];
  }

  /// Fetches specific quotes by id, for the favourites list. `whereIn` on
  /// documentId caps at 30 values, well above [AuthService.maxFreeFavorites]
  /// - if that cap ever grows past 30 this needs chunking, not before.
  /// Firestore doesn't preserve input order, so callers that care about
  /// order (e.g. most-recently-favourited first) need to re-sort by id.
  Future<List<DailyQuote>> getQuotesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _db
        .collection('DailyQuotes')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snap.docs.map((d) => DailyQuote.fromMap(d.id, d.data())).toList();
  }

  // ---------------- Quiz (FR-10) ----------------

  /// Fetches [count] questions drawn at random from the bank, optionally
  /// restricted to one Learn [category] — used by the topic assessment,
  /// which always passes `count: null` (every question in the topic; 6-19
  /// questions is small enough that "all of them" is the only sensible
  /// assessment size) and so never exercises [_drawRandomQuestion] with a
  /// category filter. That combination would need a `category`+`random`
  /// composite index this app doesn't have — if a future caller wants a
  /// small sampled [count] *and* a [category] together, add one first.
  ///
  /// Every question document carries a `random` value, spaced evenly across
  /// [0, 1) by `scripts/seed_quiz_questions.js`. Drawing one question is a
  /// `random >= pivot` cursor query with `limit(1)`, so a quiz costs about
  /// [count] document reads rather than downloading the whole collection.
  Future<List<QuizQuestion>> getQuizQuestions({int? count, String? category}) async {
    Query<Map<String, dynamic>> col = _db.collection('QuizQuestions');
    if (category != null) col = col.where('category', isEqualTo: category);

    // An aggregation query is billed at a small fraction of a document read,
    // so it is much cheaper than fetching documents to learn how many exist.
    final total = (await col.count().get()).count ?? 0;
    if (total == 0) return [];

    // Sampling only pays off while a quiz wants a small slice of the bank.
    // Past roughly half, repeat draws make a single full fetch cheaper.
    if (count == null || count * 2 >= total) {
      final snap = await col.get();
      final all = snap.docs.map(_toQuestion).toList()..shuffle(_random);
      return count != null && count < all.length ? all.sublist(0, count) : all;
    }

    final picked = <String, QuizQuestion>{};

    // Independent pivots can land on the same document, so each round fires
    // the outstanding draws in parallel and the next round re-draws whatever
    // came back duplicated. Later rounds only run when a round came up short,
    // so a generous cap costs nothing in the common case and keeps a quiz
    // from ever being handed fewer questions than it asked for.
    for (var round = 0; round < 8 && picked.length < count; round++) {
      final draws = await Future.wait(
        List.generate(count - picked.length, (_) => _drawRandomQuestion(col)),
      );
      for (final doc in draws) {
        if (doc != null) picked[doc.id] = _toQuestion(doc);
      }
    }

    return picked.values.toList()..shuffle(_random);
  }

  /// Reads a single question from a random position in the `random` ordering.
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _drawRandomQuestion(
    Query<Map<String, dynamic>> col,
  ) async {
    var snap = await col
        .where('random', isGreaterThanOrEqualTo: _random.nextDouble())
        .orderBy('random')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      // The pivot landed past the highest value; wrap around to the start.
      snap = await col.orderBy('random').limit(1).get();
    }
    return snap.docs.isEmpty ? null : snap.docs.first;
  }

  QuizQuestion _toQuestion(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final question = QuizQuestion.fromMap(doc.id, doc.data());
    // Options are stored pre-shuffled, but reshuffling per attempt keeps the
    // answer out of the same slot when a question comes around again.
    question.options.shuffle(_random);
    return question;
  }

  Future<void> saveQuizResult(QuizResult result) {
    return _db.collection('QuizResults').doc(result.resultId).set(result.toMap());
  }

  Stream<List<QuizResult>> watchQuizHistory(String uid) {
    return _db
        .collection('QuizResults')
        .where('uid', isEqualTo: uid)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => QuizResult.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Learn (topic paths) ----------------

  /// Every question in [category], in fixed lesson order (ascending `order`,
  /// assigned per-category by scripts/seed_quiz_questions.js). Unlike
  /// [getQuizQuestions] this is never sampled — a lesson walks every
  /// question in the topic once, in the same sequence every time.
  Future<List<QuizQuestion>> getLessonQuestions(String category) async {
    final snap = await _db
        .collection('QuizQuestions')
        .where('category', isEqualTo: category)
        .orderBy('order')
        .get();
    return snap.docs.map((d) => QuizQuestion.fromMap(d.id, d.data())).toList();
  }

  Stream<List<LearnProgress>> watchLearnProgress(String uid) {
    return _db
        .collection('LearnProgress')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => LearnProgress.fromMap(d.id, d.data())).toList());
  }

  /// Records [questionId] as walked in [category]'s lesson sequence.
  /// [lessonsDone] is the caller-computed "has every question in this
  /// category now been through the lesson at least once" decision — this
  /// method doesn't re-derive it, same "caller decides, service persists"
  /// split as [logProgress].
  Future<void> logLessonQuestion(
    String uid,
    String category,
    String questionId, {
    required bool lessonsDone,
  }) {
    return _db.collection('LearnProgress').doc('${uid}_$category').set({
      'uid': uid,
      'category': category,
      'lessonQuestionIds': FieldValue.arrayUnion([questionId]),
      'lessonsDone': lessonsDone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAssessmentResult(
    String uid,
    String category, {
    required int score,
    required int total,
  }) {
    return _db.collection('LearnProgress').doc('${uid}_$category').set({
      'uid': uid,
      'category': category,
      'assessmentDone': true,
      'assessmentScore': score,
      'assessmentTotal': total,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------- Prayer tracking ----------------

  /// The [day] record, or null while nothing has been logged for it. A query
  /// rather than a document get: the owner-only rule checks
  /// `resource.data.uid`, which a document that doesn't exist yet doesn't
  /// have, so a plain get of today's not-yet-created record would be denied.
  Stream<PrayerLog?> watchPrayerLog(String uid, DateTime day) {
    return _db
        .collection('PrayerLogs')
        .where('uid', isEqualTo: uid)
        .where('day', isEqualTo: PrayerLog.dayKey(day))
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : PrayerLog.fromMap(snap.docs.first.data()));
  }

  /// Sets or, with a null [status], clears one prayer on [day]'s record,
  /// creating the record on first use. One document per user per day keeps
  /// a month of history at about 30 reads.
  Future<void> setPrayerStatus(String uid, DateTime day, String prayerKey, PrayerStatus? status) {
    return _db.collection('PrayerLogs').doc('${uid}_${PrayerLog.dayKey(day)}').set({
      ...PrayerLog.baseFields(uid, day),
      PrayerLog.fieldFor(prayerKey): status?.name ?? FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  // ---------------- Account deletion (Play Store data-deletion requirement) ----------------

  /// Permanently deletes every Firestore document [uid] owns: all
  /// Habits/HabitLogs/QuizResults/LearnProgress/PrayerLogs/Notifications/
  /// Settings docs, then the Users/{uid} profile itself. Irreversible — no grace
  /// period.
  ///
  /// Excludes PrayerCache (shared cache keyed by rounded lat/lng + date, not
  /// owned by any uid — see docs/privacy-policy.md §4) and QuizQuestions/
  /// DailyQuotes (public content libraries).
  ///
  /// Users is deleted *last*: if this fails partway, leaving Users/{uid} in
  /// place keeps the account "existing" so the whole wipe is safely
  /// retryable (re-querying an already-emptied collection is a no-op).
  ///
  /// Must run while [uid] is still `request.auth.uid` — the owner-only
  /// rules need that match, so call this before deleting the Firebase Auth
  /// user or signing out.
  Future<void> deleteAllUserData(String uid) async {
    const ownedCollections = [
      'Habits', 'HabitLogs', 'QuizResults', 'LearnProgress', 'PrayerLogs', 'Notifications',
      'Settings',
    ];
    for (final name in ownedCollections) {
      await _deleteQueryInChunks(_db.collection(name).where('uid', isEqualTo: uid));
    }
    await _db.collection('Users').doc(uid).delete();
  }

  /// Deletes every document [query] matches, in batches of at most 500
  /// writes (Firestore's per-batch cap). This app's per-user volumes are
  /// small, so a single batch is the normal case — chunking is defensive.
  Future<void> _deleteQueryInChunks(Query<Map<String, dynamic>> query) async {
    const chunkSize = 500;
    final snap = await query.get();
    for (var i = 0; i < snap.docs.length; i += chunkSize) {
      final batch = _db.batch();
      for (final doc in snap.docs.skip(i).take(chunkSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
