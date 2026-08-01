import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../models/daily_quote.dart';

/// FR-04 / FR-05 / FR-06 / FR-09 / FR-10 / FR-11 / FR-12
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  Future<List<QuizQuestion>> getQuizQuestions({int limit = 10}) async {
    final snap = await _db.collection('QuizQuestions').limit(limit).get();
    return snap.docs.map((d) => QuizQuestion.fromMap(d.id, d.data())).toList();
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
