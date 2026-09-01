import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/firestore_service.dart';

/// Kinds of error [HabitProvider] can surface. Kept as a type rather than a
/// pre-formatted English sentence so the UI layer can localize the message
/// (providers stay `BuildContext`/`AppLocalizations`-free).
enum HabitErrorType { syncFailed, duplicateTitle, updateFailed, deleteFailed }

/// Streak lengths a milestone banner celebrates. Ordered ascending —
/// [HabitProvider._checkMilestone] relies on that to find the highest one
/// crossed in a single jump.
const List<int> kMilestoneDays = [3, 7, 30, 100, 365];

/// A just-crossed streak milestone for one habit, queued for the dashboard
/// to celebrate. [days] is always a value from [kMilestoneDays].
class MilestoneEvent {
  final String habitId;
  final String habitTitle;
  final int days;

  const MilestoneEvent({required this.habitId, required this.habitTitle, required this.days});
}

class HabitProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final _uuid = const Uuid();

  StreamSubscription<List<Habit>>? _habitsSub;
  String? _listeningUid;

  List<Habit> _habits = [];
  List<Habit> get habits => _habits;

  HabitErrorType? _errorType;
  String? _errorDetail;
  HabitErrorType? get errorType => _errorType;
  String? get errorDetail => _errorDetail;
  bool get hasError => _errorType != null;

  void clearError() {
    _errorType = null;
    _errorDetail = null;
    notifyListeners();
  }

  // ---------------- Streak milestones ----------------

  /// Queued rather than a single nullable event: [streakFor] is called
  /// concurrently for every visible habit (Dashboard and Habits tab both
  /// stay mounted under the bottom nav's `IndexedStack`), so more than one
  /// habit can cross a milestone in the same frame — most likely right
  /// after this feature ships, when existing streaks are seen for the
  /// first time and each celebrates once. The dashboard shows one at a
  /// time and calls [consumeMilestone] to advance to the next.
  final List<MilestoneEvent> _milestoneQueue = [];
  MilestoneEvent? get pendingMilestone => _milestoneQueue.isEmpty ? null : _milestoneQueue.first;

  void consumeMilestone() {
    if (_milestoneQueue.isEmpty) return;
    _milestoneQueue.removeAt(0);
    notifyListeners();
  }

  /// Compares [streak] against the last streak length seen for [habit],
  /// persisted locally (device-only, like [ThemeProvider]'s prefs — a
  /// streak is recomputed from `HabitLogs` on demand rather than stored,
  /// so there's nowhere server-side to keep a watermark). Queues the
  /// highest [kMilestoneDays] entry crossed since then, if any.
  ///
  /// The watermark defaults to 0 for a habit never seen before, so a habit
  /// whose streak is already past a milestone the first time this runs
  /// (e.g. right after this feature ships) celebrates immediately for the
  /// highest milestone already reached, once — rather than staying silent
  /// about a streak the user already earned.
  Future<void> _checkMilestone(Habit habit, int streak) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'streak_watermark_${habit.habitId}';
    final lastSeen = prefs.getInt(key) ?? 0;
    if (streak <= lastSeen) return;

    final crossed = kMilestoneDays.where((d) => d > lastSeen && d <= streak);
    if (crossed.isNotEmpty) {
      final days = crossed.last;
      final alreadyQueued =
          _milestoneQueue.any((m) => m.habitId == habit.habitId && m.days == days);
      if (!alreadyQueued) {
        _milestoneQueue.add(MilestoneEvent(habitId: habit.habitId, habitTitle: habit.title, days: days));
        notifyListeners();
      }
    }
    await prefs.setInt(key, streak);
  }

  void _setError(HabitErrorType type, String detail) {
    _errorType = type;
    _errorDetail = detail;
    notifyListeners();
  }

  double get completionPercentage {
    if (_habits.isEmpty) return 0;
    final done = _habits.where((h) => h.isCompletedToday).length;
    return done / _habits.length;
  }

  void listenToHabits(String uid) {
    // Avoid stacking duplicate listeners if this is called more than once
    // for the same user (e.g. DashboardScreen rebuilding).
    if (_listeningUid == uid && _habitsSub != null) return;

    _habitsSub?.cancel();
    _listeningUid = uid;

    _habitsSub = _service.watchHabits(uid).listen(
      (habits) {
        _habits = habits;
        _errorType = null;
        _errorDetail = null;
        notifyListeners();
      },
      onError: (Object e) {
        // This is the fix for "works once, then needs a restart": previously
        // an error here (e.g. a missing Firestore composite index, or a
        // permission rule rejecting the *listener* specifically) silently
        // killed the subscription with no feedback. Now it's surfaced, and
        // we retry so a transient error (e.g. brief connectivity loss)
        // recovers on its own instead of requiring an app restart.
        _setError(HabitErrorType.syncFailed, e.toString());

        _habitsSub?.cancel();
        _habitsSub = null;
        Future.delayed(const Duration(seconds: 3), () {
          if (_listeningUid == uid) {
            _listeningUid = null; // force re-subscribe
            listenToHabits(uid);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _habitsSub?.cancel();
    super.dispose();
  }

  /// Returns false without writing anything if [uid] already has a habit
  /// with the same title (case-insensitive, ignoring surrounding whitespace).
  /// Firestore has no unique-field constraint, so this is the only place
  /// duplicate titles are prevented.
  Future<bool> addHabit({
    required String uid,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    List<int> selectedDays = const [],
    int? reminderHour,
    int? reminderMinute,
    HabitTrackingType trackingType = HabitTrackingType.yesNo,
    int numericTarget = 1,
    String numericUnit = '',
    int timerTargetMinutes = 10,
    List<String> checklistItems = const [],
    int ratingScale = 5,
  }) async {
    final normalizedTitle = title.trim().toLowerCase();
    final isDuplicate = _habits.any(
      (h) => h.uid == uid && h.title.trim().toLowerCase() == normalizedTitle,
    );
    if (isDuplicate) {
      _setError(HabitErrorType.duplicateTitle, title.trim());
      return false;
    }

    final habit = Habit(
      habitId: _uuid.v4(),
      uid: uid,
      title: title,
      category: category,
      frequency: frequency,
      selectedDays: selectedDays,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      trackingType: trackingType,
      numericTarget: numericTarget,
      numericUnit: numericUnit,
      timerTargetMinutes: timerTargetMinutes,
      checklistItems: checklistItems,
      ratingScale: ratingScale,
    );
    await _service.addHabit(habit);
    return true;
  }

  /// Saves edits to an existing habit, keeping its id, completion state, and
  /// creation date. [original] must be the habit as currently loaded, so
  /// unrelated in-flight state (e.g. today's completion) isn't clobbered.
  Future<bool> updateHabit({
    required Habit original,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    List<int> selectedDays = const [],
    int? reminderHour,
    int? reminderMinute,
    HabitTrackingType trackingType = HabitTrackingType.yesNo,
    int numericTarget = 1,
    String numericUnit = '',
    int timerTargetMinutes = 10,
    List<String> checklistItems = const [],
    int ratingScale = 5,
  }) async {
    final normalizedTitle = title.trim().toLowerCase();
    final isDuplicate = _habits.any(
      (h) =>
          h.uid == original.uid &&
          h.habitId != original.habitId &&
          h.title.trim().toLowerCase() == normalizedTitle,
    );
    if (isDuplicate) {
      _setError(HabitErrorType.duplicateTitle, title.trim());
      return false;
    }

    final updated = Habit(
      habitId: original.habitId,
      uid: original.uid,
      title: title,
      category: category,
      frequency: frequency,
      completed: original.completed,
      lastCompletedDate: original.lastCompletedDate,
      selectedDays: selectedDays,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      trackingType: trackingType,
      numericTarget: numericTarget,
      numericUnit: numericUnit,
      timerTargetMinutes: timerTargetMinutes,
      checklistItems: checklistItems,
      ratingScale: ratingScale,
      todayProgressValue: original.todayProgressValue,
      createdAt: original.createdAt,
    );

    try {
      await _service.updateHabit(updated);
      return true;
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
      return false;
    }
  }

  /// Yes/No logging, and the Milestone-1 stopgap for checklist/rating.
  Future<void> toggleComplete(Habit habit) async {
    try {
      await _service.logProgress(habit, status: !habit.isCompletedToday);
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Numeric tracking: +1 per tap, persisted as the new running total.
  /// Satisfied once the count reaches [Habit.numericTarget].
  Future<void> logNumericProgress(Habit habit) async {
    final current = habit.hasProgressToday ? habit.todayProgressValue : 0;
    final next = current + 1;
    try {
      await _service.logProgress(
        habit,
        status: next >= habit.numericTarget,
        numericValue: next,
      );
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Timer tracking: persists an absolute elapsed-seconds checkpoint.
  /// Satisfied once elapsed reaches [Habit.timerTargetMinutes].
  Future<void> logTimerProgress(Habit habit, {required int elapsedSeconds}) async {
    final targetSeconds = habit.timerTargetMinutes * 60;
    try {
      await _service.logProgress(
        habit,
        status: elapsedSeconds >= targetSeconds,
        timerElapsedSeconds: elapsedSeconds,
      );
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Rating tracking: any tap commits immediately and completes the day,
  /// matching the app's one-tap completion model elsewhere.
  Future<void> logRating(Habit habit, int value) async {
    try {
      await _service.logProgress(habit, status: true, ratingValue: value);
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Checklist tracking: records which items are checked off; satisfied
  /// once every item in [Habit.checklistItems] is present in [doneItems].
  Future<void> logChecklistProgress(Habit habit, List<String> doneItems) async {
    try {
      await _service.logProgress(
        habit,
        status: habit.checklistItems.isNotEmpty &&
            doneItems.toSet().containsAll(habit.checklistItems),
        checklistDone: doneItems,
      );
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Avoidance tracking: records a slip. This is the *only* write an
  /// avoidance habit ever makes — silence (no call at all) is what keeps
  /// its streak going, so this always logs `status: false`.
  Future<void> logAvoidanceSlip(Habit habit) async {
    try {
      await _service.logProgress(habit, status: false);
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _service.deleteHabit(habitId);
    } catch (e) {
      _setError(HabitErrorType.deleteFailed, e.toString());
    }
  }

  Future<int> streakFor(Habit habit) async {
    final logs = await _service.watchHabitLogs(habit.uid, habit.habitId).first;
    final streak = _service.calculateStreak(
      logs,
      frequency: habit.frequency,
      selectedDays: habit.selectedDays,
      trackingType: habit.trackingType,
    );
    unawaited(_checkMilestone(habit, streak));
    return streak;
  }

  /// This week's completion, one bool per day (Mon..Sun).
  Future<List<bool>> weekFor(Habit habit) async {
    final logs = await _service.watchHabitLogs(habit.uid, habit.habitId).first;
    return _service.weekCompletion(logs, trackingType: habit.trackingType);
  }
}