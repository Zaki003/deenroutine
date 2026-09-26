import '../models/habit.dart';
import '../models/habit_log.dart';

/// Streak lengths the Profile's Habit insights shows as badges, earned by
/// any habit's longest-ever streak. Separate from [kMilestoneDays] (the
/// dashboard's celebration banners): 40 days is the traditional mark for
/// building a practice.
const List<int> kInsightMilestoneDays = [7, 30, 40, 100];

/// How many weeks the free grid covers. A longer history is a premium idea
/// for later.
const int kInsightGridWeeks = 4;

/// The Profile's habit summary, over recurring habits only (a one-off to-do
/// has no rhythm to summarize, same as everywhere else streaks are shown).
class HabitInsights {
  /// Highest current streak across habits.
  final int bestStreak;

  /// Longest streak any habit has ever had - what the milestones are earned
  /// by, so a badge stays earned after a streak breaks.
  final int longestEver;

  /// Done out of due over the grid's weeks, not counting today (still in
  /// progress). Null before anything was due.
  final int? ratePercent;

  /// Every completed day ever logged, across habits. Avoidance habits don't
  /// count here: their wins are silence, not check-ins.
  final int checkIns;

  /// [kInsightGridWeeks] Mon-Sun weeks, oldest first, flattened: done / due
  /// for each day, or null when nothing was due or the day hasn't come yet.
  final List<double?> grid;

  /// This week, Mon..Sun: which habits were done each day, and the week's
  /// done / due totals (due counts the whole week's scheduled habit-days).
  final List<List<String>> weekDoneTitles;
  final int weekDone;
  final int weekDue;

  const HabitInsights({
    required this.bestStreak,
    required this.longestEver,
    required this.ratePercent,
    required this.checkIns,
    required this.grid,
    required this.weekDoneTitles,
    required this.weekDone,
    required this.weekDue,
  });

  bool reached(int milestoneDays) => longestEver >= milestoneDays;
}

/// [logsByHabit] must hold each habit's complete history including today.
/// [currentStreak] is [FirestoreService.calculateStreak] for that habit, so
/// the number here always matches the one on the habit's own row.
///
/// Success follows the same rule as the streaks: a `status: true` log for
/// most habits; for an avoidance habit, a scheduled day with no log at all.
HabitInsights computeHabitInsights({
  required List<Habit> habits,
  required Map<String, List<HabitLog>> logsByHabit,
  required DateTime now,
  required int Function(Habit habit, List<HabitLog> logs) currentStreak,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
  final gridStart = DateTime(monday.year, monday.month, monday.day - 7 * (kInsightGridWeeks - 1));

  final tracked = [
    for (final h in habits)
      if (h.frequency != HabitFrequency.once) (habit: h, days: _byDay(logsByHabit[h.habitId] ?? const [])),
  ];

  bool due(Habit h, DateTime day) =>
      !day.isBefore(_midnight(h.createdAt)) &&
      (h.frequency != HabitFrequency.specificDays || h.selectedDays.contains(day.weekday % 7));
  bool succeeded(Habit h, Map<DateTime, bool> days, DateTime day) =>
      h.trackingType == HabitTrackingType.avoidance
          ? !day.isAfter(today) && !days.containsKey(day)
          : days[day] == true;

  // ---- Grid and 4-week rate
  final grid = <double?>[];
  var rateDone = 0, rateDue = 0;
  for (var i = 0; i < kInsightGridWeeks * 7; i++) {
    final day = DateTime(gridStart.year, gridStart.month, gridStart.day + i);
    if (day.isAfter(today)) {
      grid.add(null);
      continue;
    }
    var d = 0, done = 0;
    for (final t in tracked) {
      if (!due(t.habit, day)) continue;
      d++;
      if (succeeded(t.habit, t.days, day)) done++;
    }
    grid.add(d == 0 ? null : done / d);
    if (day != today) {
      rateDue += d;
      rateDone += done;
    }
  }

  // ---- This week
  final weekDoneTitles = <List<String>>[];
  var weekDone = 0, weekDue = 0;
  for (var i = 0; i < 7; i++) {
    final day = DateTime(monday.year, monday.month, monday.day + i);
    final titles = <String>[];
    for (final t in tracked) {
      if (!due(t.habit, day)) continue;
      weekDue++;
      if (succeeded(t.habit, t.days, day)) titles.add(t.habit.title);
    }
    weekDone += titles.length;
    weekDoneTitles.add(titles);
  }

  // ---- Streaks and check-ins
  var best = 0, longest = 0, checkIns = 0;
  for (final t in tracked) {
    final h = t.habit;
    final streak = currentStreak(h, logsByHabit[h.habitId] ?? const []);
    if (streak > best) best = streak;
    final ever = _longestStreak(h, t.days, today, due, succeeded);
    if (ever > longest) longest = ever;
    if (h.trackingType != HabitTrackingType.avoidance) {
      checkIns += t.days.values.where((ok) => ok).length;
    }
  }

  return HabitInsights(
    bestStreak: best,
    longestEver: longest < best ? best : longest,
    ratePercent: rateDue == 0 ? null : (rateDone * 100 / rateDue).round(),
    checkIns: checkIns,
    grid: grid,
    weekDoneTitles: weekDoneTitles,
    weekDone: weekDone,
    weekDue: weekDue,
  );
}

/// The longest run of consecutive scheduled days [h] succeeded on, from its
/// creation to today. Unscheduled days are skipped; today not being done
/// yet doesn't end a run.
int _longestStreak(
  Habit h,
  Map<DateTime, bool> days,
  DateTime today,
  bool Function(Habit, DateTime) due,
  bool Function(Habit, Map<DateTime, bool>, DateTime) succeeded,
) {
  var longest = 0, run = 0;
  var day = _midnight(h.createdAt);
  // Bounded like calculateStreak, against a createdAt far in the past.
  for (var i = 0; i < 3660 && !day.isAfter(today); i++) {
    if (due(h, day)) {
      if (succeeded(h, days, day)) {
        run++;
        if (run > longest) longest = run;
      } else if (day != today) {
        run = 0;
      }
    }
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return longest;
}

Map<DateTime, bool> _byDay(List<HabitLog> logs) =>
    {for (final l in logs) _midnight(l.date): l.status};

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
