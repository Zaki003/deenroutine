/// This week's totals across the recurring habits, computed from each habit's
/// Mon-Sun completion flags (one `List<bool>` per habit, in habit order) -
/// shared by the Profile screen and the Friday summary notification so both
/// agree on what "best habit" and "done" mean.
class WeekStats {
  /// Habits completed on each day, Mon..Sun.
  final List<int> dayCounts;
  final int totalDone;

  /// Habit-days available this week (habits x 7). Not schedule-aware: a
  /// twice-a-week habit can never fill its share.
  final int totalPossible;

  /// Index of the habit with the most completed days this week, or -1 when
  /// nothing was completed at all. The first one wins a tie.
  final int bestIndex;
  final int bestCount;

  const WeekStats({
    required this.dayCounts,
    required this.totalDone,
    required this.totalPossible,
    required this.bestIndex,
    required this.bestCount,
  });
}

WeekStats computeWeekStats(List<List<bool>> weeks) {
  final dayCounts = List.generate(7, (i) => weeks.where((w) => w[i]).length);
  var bestIndex = -1;
  var bestCount = 0;
  for (var i = 0; i < weeks.length; i++) {
    final count = weeks[i].where((done) => done).length;
    if (count > bestCount) {
      bestCount = count;
      bestIndex = i;
    }
  }
  return WeekStats(
    dayCounts: dayCounts,
    totalDone: dayCounts.fold(0, (sum, c) => sum + c),
    totalPossible: weeks.length * 7,
    bestIndex: bestIndex,
    bestCount: bestCount,
  );
}
