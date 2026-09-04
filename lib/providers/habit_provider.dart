import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/analytics_service.dart';
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
  final AnalyticsService _analytics = AnalyticsService();
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
        _analytics.logStreakMilestone(days: days);
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
    String? templateId,
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
    _analytics.logHabitCreated(
      category: category.name,
      trackingType: trackingType.name,
      templateId: templateId,
    );
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

  /// Fires the platform's light haptic, and logs the (opt-in-only)
  /// `habit_completed` analytics event, the instant a habit's completion
  /// transitions to done. The haptic is the felt confirmation for the
  /// common case — finishing one habit, which happens several times a day —
  /// kept deliberately quieter than the Barakah Circle burst (all done
  /// today) and the milestone banner (streak thresholds), which are rarer
  /// and earn a bigger moment.
  void _confirmCompletion(bool completing, HabitTrackingType trackingType) {
    if (!completing) return;
    HapticFeedback.lightImpact();
    _analytics.logHabitCompleted(trackingType: trackingType.name);
  }

  /// Yes/No logging, and the Milestone-1 stopgap for checklist/rating.
  Future<void> toggleComplete(Habit habit) async {
    final completing = !habit.isCompletedToday;
    try {
      await _service.logProgress(habit, status: completing);
      _confirmCompletion(completing, habit.trackingType);
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Numeric tracking: +1 per tap, persisted as the new running total.
  /// Satisfied once the count reaches [Habit.numericTarget].
  Future<void> logNumericProgress(Habit habit) async {
    final current = habit.hasProgressToday ? habit.todayProgressValue : 0;
    final next = current + 1;
    final completing = next >= habit.numericTarget;
    try {
      await _service.logProgress(
        habit,
        status: completing,
        numericValue: next,
      );
      _confirmCompletion(completing, habit.trackingType);
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Timer tracking: persists an absolute elapsed-seconds checkpoint.
  /// Satisfied once elapsed reaches [Habit.timerTargetMinutes].
  Future<void> logTimerProgress(Habit habit, {required int elapsedSeconds}) async {
    final targetSeconds = habit.timerTargetMinutes * 60;
    final completing = elapsedSeconds >= targetSeconds && !habit.isCompletedToday;
    try {
      await _service.logProgress(
        habit,
        status: elapsedSeconds >= targetSeconds,
        timerElapsedSeconds: elapsedSeconds,
      );
      _confirmCompletion(completing, habit.trackingType);
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Rating tracking: any tap commits immediately and completes the day,
  /// matching the app's one-tap completion model elsewhere.
  Future<void> logRating(Habit habit, int value) async {
    final completing = !habit.isCompletedToday;
    try {
      await _service.logProgress(habit, status: true, ratingValue: value);
      _confirmCompletion(completing, habit.trackingType);
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Checklist tracking: records which items are checked off; satisfied
  /// once every item in [Habit.checklistItems] is present in [doneItems].
  Future<void> logChecklistProgress(Habit habit, List<String> doneItems) async {
    final newStatus = habit.checklistItems.isNotEmpty &&
        doneItems.toSet().containsAll(habit.checklistItems);
    final completing = newStatus && !habit.isCompletedToday;
    try {
      await _service.logProgress(
        habit,
        status: newStatus,
        checklistDone: doneItems,
      );
      _confirmCompletion(completing, habit.trackingType);
    } catch (e) {
      _setError(HabitErrorType.updateFailed, e.toString());
    }
  }

  /// Undoes an accidental completion, regardless of tracking type — the
  /// escape hatch for the common "meant to tap something else" mistake.
  /// Yes/No already has this via [toggleComplete]'s own toggle, and
  /// checklist already has a more precise per-item undo (see
  /// [logChecklistProgress]), but both call sites reach this too (the
  /// Habits tab's undo indicator is uniform across every type, so it
  /// doesn't know or care which one it's looking at).
  ///
  /// Numeric/timer roll back to just under target rather than to 0, so an
  /// accidental *extra* tap doesn't wipe real progress; checklist keeps
  /// whichever items were checked (only [completed] flips, never a bare
  /// `logProgress` call with no `checklistDone`, which would otherwise
  /// silently clear it back to an empty list); rating clears back to
  /// unrated, since there's no earlier value worth restoring.
  Future<void> undoCompletion(Habit habit) async {
    try {
      switch (habit.trackingType) {
        case HabitTrackingType.numeric:
          await _service.logProgress(
            habit,
            status: false,
            numericValue: (habit.numericTarget - 1).clamp(0, habit.numericTarget),
          );
        case HabitTrackingType.timer:
          final targetSeconds = habit.timerTargetMinutes * 60;
          await _service.logProgress(
            habit,
            status: false,
            timerElapsedSeconds: (targetSeconds - 1).clamp(0, targetSeconds),
          );
        case HabitTrackingType.checklist:
          await _service.logProgress(
            habit,
            status: false,
            checklistDone: habit.hasProgressToday ? habit.todayChecklistDone : const [],
          );
        case HabitTrackingType.rating:
        case HabitTrackingType.yesNo:
        case HabitTrackingType.avoidance:
          await _service.logProgress(habit, status: false);
      }
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

  Future<void> deleteHabit(Habit habit) async {
    try {
      await _service.deleteHabit(habit);
    } catch (e) {
      _setError(HabitErrorType.deleteFailed, e.toString());
    }
  }

  Future<int> streakFor(Habit habit) async {
    final logs = await _service.watchHabitLogs(habit.uid, habit.habitId).first;
    final streak = _service.calculateStreak(
      logs,
      createdAt: habit.createdAt,
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