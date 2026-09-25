import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../utils/daily_quote_schedule.dart' show upcomingDailyTimes;
import '../utils/habit_notification_text.dart';
import '../utils/notification_plan.dart';
import '../utils/week_stats.dart';
import 'notification_service.dart';

/// The user's choices that shape the habit-related notifications - a plain
/// snapshot, so the scheduler never has to know about providers.
class NotificationPrefs {
  final bool encouragingReminders;
  final bool streakNudge;
  final int streakHour;
  final int streakMinute;
  final bool weeklySummary;
  final bool comeback;

  const NotificationPrefs({
    required this.encouragingReminders,
    required this.streakNudge,
    required this.streakHour,
    required this.streakMinute,
    required this.weeklySummary,
    required this.comeback,
  });

  String get signature =>
      '$encouragingReminders:$streakNudge:$streakHour:$streakMinute:'
      '$weeklySummary:$comeback';
}

class _Superseded implements Exception {
  const _Superseded();
}

typedef _Put = Future<void> Function({
  required int id,
  required DateTime when,
  required NotificationText text,
  required NotificationKind kind,
  bool exact,
});

/// Owns every habit-related notification: each habit's reminders, the streak
/// nudge, the Friday summary, and the come-back messages.
///
/// Local notifications can't change their text or check anything when they
/// fire, so all of it is worked out ahead of time and rebuilt whenever
/// something changes (the app opens, a habit is completed or edited, a
/// setting flips): each habit gets its next [kReminderWindowDays] days
/// scheduled individually - which is what lets the wording rotate and lets
/// today's reminder be dropped once the habit is done - and anything the
/// current state no longer wants is swept away.
class HabitNotificationScheduler {
  final NotificationService _notifications;

  HabitNotificationScheduler(this._notifications);

  /// Rebuilds the whole schedule from [habits]. [isCurrent] lets a caller
  /// abandon a run that's been superseded (a newer run, a logout) before it
  /// sends another schedule call.
  Future<void> reschedule({
    required List<Habit> habits,
    required NotificationPrefs prefs,
    required AppLocalizations l10n,
    required bool Function() isCurrent,
    required Future<int> Function(Habit habit, DateTime day) streakAsOf,
    required Future<List<bool>> Function(Habit habit) weekFor,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final desired = <int>{};

    Future<void> put({
      required int id,
      required DateTime when,
      required NotificationText text,
      required NotificationKind kind,
      bool exact = false,
    }) async {
      if (!isCurrent()) throw const _Superseded();
      // Counted as wanted even if scheduling throws, so a hiccup never
      // cancels a notification that's still pending from an earlier run.
      desired.add(id);
      try {
        await _notifications.schedule(
          id: id,
          when: when,
          title: text.title,
          body: text.body,
          kind: kind,
          exact: exact,
        );
      } catch (e) {
        debugPrint('Scheduling notification $id failed: $e');
      }
    }

    try {
      await _scheduleReminders(habits, prefs, l10n, clock, put);
      if (prefs.streakNudge) {
        await _scheduleStreakNudge(habits, prefs, l10n, clock, streakAsOf, put);
      }
      if (prefs.weeklySummary) {
        await _scheduleWeeklySummary(habits, l10n, clock, weekFor, put);
      }
      if (prefs.comeback && habits.isNotEmpty) {
        await _scheduleComeback(l10n, clock, put);
      }
      if (!isCurrent()) return;
      await _sweep(habits, desired);
    } on _Superseded {
      return;
    }
  }

  Future<void> _scheduleReminders(List<Habit> habits, NotificationPrefs prefs,
      AppLocalizations l10n, DateTime clock, _Put put) async {
    for (final habit in habits) {
      final hour = habit.reminderHour;
      final minute = habit.reminderMinute;
      if (hour == null || minute == null) continue;

      if (habit.frequency == HabitFrequency.once) {
        // A to-do's reminder is a single moment on its due date, and needs
        // nothing once it's done. Plain wording: it should say what it is.
        final due = habit.dueDate;
        if (due == null || habit.completed) continue;
        await put(
          id: habitOneOffReminderId(habit.habitId),
          when: DateTime(due.year, due.month, due.day, hour, minute),
          text: (
            title: l10n.reminderNotificationTitle,
            body: l10n.reminderNotificationBody(habit.title),
          ),
          kind: NotificationKind.reminder,
          exact: true,
        );
        continue;
      }

      for (final when in upcomingDailyTimes(clock,
          hour: hour, minute: minute, count: kReminderWindowDays)) {
        if (!habit.isDueOn(when)) continue;
        if (isSameDay(when, clock) && skipReminderToday(habit)) continue;
        await put(
          id: habitReminderId(habit.habitId, when),
          when: when,
          text: habitReminderText(l10n, habit, when,
              encouraging: prefs.encouragingReminders),
          kind: NotificationKind.reminder,
          exact: true,
        );
      }
    }
  }

  /// One nudge, for whichever habit has the most to lose at the next evening
  /// slot. Only ever the *next* slot, and rebuilt on every change, so the
  /// streak number in the text is what it will really be when it fires - and
  /// finishing the habit cancels it. If nothing's at risk this evening, it
  /// looks at tomorrow's instead (a streak kept alive today is at risk then).
  Future<void> _scheduleStreakNudge(
      List<Habit> habits,
      NotificationPrefs prefs,
      AppLocalizations l10n,
      DateTime clock,
      Future<int> Function(Habit, DateTime) streakAsOf,
      _Put put) async {
    final first = nextStreakNudgeTime(clock,
        hour: prefs.streakHour, minute: prefs.streakMinute);
    final slots = [
      first,
      if (isSameDay(first, clock))
        DateTime(first.year, first.month, first.day + 1, first.hour,
            first.minute),
    ];

    for (final slot in slots) {
      final candidates = <({Habit habit, int streak})>[];
      for (final habit in habits) {
        if (!isStreakNudgeCandidate(habit, slot, clock)) continue;
        try {
          candidates.add((habit: habit, streak: await streakAsOf(habit, slot)));
        } catch (e) {
          debugPrint('Streak lookup failed for ${habit.habitId}: $e');
        }
      }
      final pick = pickStreakNudge(candidates);
      if (pick == null) continue;
      await put(
        id: streakNudgeId,
        when: slot,
        text: streakNudgeText(l10n, pick.habit, pick.streak),
        kind: NotificationKind.streak,
      );
      return;
    }
  }

  /// The Friday message. It only carries numbers when this week's are known:
  /// computed now, for a Friday in the same Mon-Sun week (otherwise they'd
  /// describe the wrong week). Anything the user does in the app reschedules
  /// this, so the numbers stay current up to the moment it fires.
  Future<void> _scheduleWeeklySummary(List<Habit> habits, AppLocalizations l10n,
      DateTime clock, Future<List<bool>> Function(Habit) weekFor, _Put put) async {
    final recurring =
        habits.where((h) => h.frequency != HabitFrequency.once).toList();
    if (recurring.isEmpty) return;

    final when = nextWeeklySummaryTime(clock);
    int? done;
    String? best;
    if (isSameWeek(clock, when)) {
      try {
        final stats = computeWeekStats(await Future.wait(recurring.map(weekFor)));
        done = stats.totalDone;
        best = stats.bestIndex >= 0 ? recurring[stats.bestIndex].title : null;
      } catch (e) {
        debugPrint('Weekly stats lookup failed: $e');
      }
    }
    await put(
      id: weeklySummaryId,
      when: when,
      text: weeklySummaryText(l10n, done: done, bestHabit: best),
      kind: NotificationKind.weekly,
    );
  }

  Future<void> _scheduleComeback(
      AppLocalizations l10n, DateTime clock, _Put put) async {
    final times = comebackTimes(clock);
    await put(
      id: comebackFirstId,
      when: times[0],
      text: comebackText(l10n, second: false),
      kind: NotificationKind.comeback,
    );
    await put(
      id: comebackSecondId,
      when: times[1],
      text: comebackText(l10n, second: true),
      kind: NotificationKind.comeback,
    );
  }

  /// Cancels whatever's pending in this scheduler's ID ranges that the
  /// current state doesn't want (a deleted habit, a reminder that was
  /// removed, a nudge type that was switched off), plus the one repeating
  /// reminder per habit that older versions scheduled under
  /// `title.hashCode`, which would otherwise fire alongside the new ones.
  Future<void> _sweep(List<Habit> habits, Set<int> desired) async {
    final pending = await _notifications.pendingIds();
    await _notifications.cancelIds([
      for (final id in pending)
        if ((isHabitReminderId(id) || singleSlotNudgeIds.contains(id)) &&
            !desired.contains(id))
          id,
      for (final habit in habits)
        if (habit.reminderHour != null) habit.title.hashCode,
    ]);
  }

  /// Everything this scheduler owns - for logout.
  Future<void> cancelAll() async {
    final pending = await _notifications.pendingIds();
    await _notifications.cancelIds([
      for (final id in pending)
        if (isHabitReminderId(id) || singleSlotNudgeIds.contains(id)) id,
    ]);
  }
}
