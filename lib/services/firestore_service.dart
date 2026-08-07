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
  Future<void> markHabitComplete(Habit habit, bool status) async {
    final batch = _db.batch();

    final habitRef = _db.collection('Habits').doc(habit.habitId);
    batch.update(habitRef, {'completed': status});

    final today = DateTime.now();
    final logId = '${habit.habitId}_${today.year}-${today.month}-${today.day}';
    final logRef = _db.collection('HabitLogs').doc(logId);
    final log = HabitLog(
      logId: logId,
      habitId: habit.habitId,
      date: DateTime(today.year, today.month, today.day),
      status: status,
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

  /// Computes a simple consecutive-day streak from recent logs.
  int calculateStreak(List<HabitLog> logs) {
    int streak = 0;
    DateTime cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    final byDate = {
      for (final l in logs) DateTime(l.date.year, l.date.month, l.date.day): l.status,
    };

    while (byDate[cursor] == true) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---------------- Daily motivation (FR-09) ----------------
  Future<DailyQuote?> getDailyQuote() async {
    final snap = await _db.collection('DailyQuotes').limit(50).get();
    if (snap.docs.isEmpty) return null;
    final dayIndex = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
    final doc = snap.docs[dayIndex % snap.docs.length];
    return DailyQuote.fromMap(doc.id, doc.data());
  }

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
