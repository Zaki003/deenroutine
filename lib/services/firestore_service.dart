import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../models/daily_quote.dart';

/// FR-04 / FR-05 / FR-06 / FR-09 / FR-10 / FR-11 / FR-12
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

  Future<void> deleteHabit(String habitId) {
    return _db.collection('Habits').doc(habitId).delete();
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

  Stream<List<HabitLog>> watchHabitLogs(String habitId) {
    return _db
        .collection('HabitLogs')
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
  int calculateStreak(
    List<HabitLog> logs, {
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> selectedDays = const [],
    HabitTrackingType trackingType = HabitTrackingType.yesNo,
  }) {
    bool isScheduled(DateTime day) =>
        frequency != HabitFrequency.specificDays || selectedDays.contains(day.weekday % 7);

    final byDate = {
      for (final l in logs) DateTime(l.date.year, l.date.month, l.date.day): l.status,
    };
    bool daySucceeded(DateTime day) => trackingType == HabitTrackingType.avoidance
        ? !byDate.containsKey(day)
        : byDate[day] == true;

    int streak = 0;
    DateTime cursor = DateTime.now();
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

    // Bounded a bit beyond the fetched log window so a corrupt/empty
    // selectedDays (never produced by the app's own day picker, but not
    // guaranteed for data edited directly in Firestore) can't spin forever.
    for (var i = 0; i < 400; i++) {
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
  /// The day number is counted in UTC: a local date would hand users in Sydney
  /// and Los Angeles different quotes at the same moment.
  Future<DailyQuote?> getDailyQuote() async {
    final col = _db.collection('DailyQuotes');

    final total = (await col.count().get()).count ?? 0;
    if (total == 0) return null;

    final today = DateTime.now().toUtc();
    final dayNumber =
        DateTime.utc(today.year, today.month, today.day).difference(_epoch).inDays;
    // Dart's % is never negative, so dates before the epoch still map into range.
    final index = dayNumber % total;

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

  static final DateTime _epoch = DateTime.utc(2026, 1, 1);

  // ---------------- Quiz (FR-10) ----------------

  /// Fetches [count] questions drawn at random from the bank.
  ///
  /// Every question document carries a `random` value, spaced evenly across
  /// [0, 1) by `scripts/seed_quiz_questions.js`. Drawing one question is a
  /// `random >= pivot` cursor query with `limit(1)`, so a quiz costs about
  /// [count] document reads rather than downloading the whole collection.
  Future<List<QuizQuestion>> getQuizQuestions({int? count}) async {
    final col = _db.collection('QuizQuestions');

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
    CollectionReference<Map<String, dynamic>> col,
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

  /// The single highest-scoring attempt on record for [uid] at exactly
  /// [totalQuestions] questions — a 20-question best is meaningless as a
  /// "personal best" for someone picking the 5-question quiz, so this is
  /// always scoped to one length rather than the best across all of them.
  Future<QuizResult?> getBestQuizResult(String uid, int totalQuestions) async {
    final snap = await _db
        .collection('QuizResults')
        .where('uid', isEqualTo: uid)
        .where('totalQuestions', isEqualTo: totalQuestions)
        .orderBy('score', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return QuizResult.fromMap(snap.docs.first.id, snap.docs.first.data());
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
}
