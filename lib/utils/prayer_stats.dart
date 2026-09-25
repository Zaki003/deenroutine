import '../models/prayer_log.dart';

/// The Profile's prayer summary over the last [PrayerStats.windowDays] prayer
/// days. Percentages are null when nothing in the window was due yet.
class PrayerStats {
  static const windowDays = 30;

  /// Consecutive prayer days, back from today, on which every prayer that
  /// was due got prayed. A fully excused day is skipped (paused, not
  /// broken), and today not being finished yet doesn't break it either.
  final int streak;

  /// True when the streak ran all the way back to the oldest day loaded, so
  /// the real number may be higher - shown as "90+".
  final bool streakCapped;

  /// Prayed (qada included) out of due, across all five prayers.
  final int? prayedPercent;

  /// On time out of prayed.
  final int? onTimePercent;

  /// Prayed out of due, per prayer key.
  final Map<String, int?> perPrayerPercent;

  /// [PrayerLog.prayerKeys] order, then oldest day to newest; null where
  /// nothing was logged (or the day came before tracking started).
  final Map<String, List<PrayerStatus?>> grid;

  /// The prayer that stands out as hardest, or null when none clearly does.
  final String? weakestPrayer;

  const PrayerStats({
    required this.streak,
    required this.streakCapped,
    required this.prayedPercent,
    required this.onTimePercent,
    required this.perPrayerPercent,
    required this.grid,
    required this.weakestPrayer,
  });
}

/// [logsByDay] is keyed by [PrayerLog.dayKey] and must include [today]'s
/// record if there is one. [oldestLoaded] is the first day that was
/// queried, which caps how far back the streak can look. [startedToday] is
/// which of today's prayers have begun - the rest aren't due yet.
///
/// Days before the first logged one don't count against anything: someone
/// who started tracking a week ago has a week of stats, not 23 missed days.
/// After that, an unlogged prayer that was due counts as not prayed.
PrayerStats computePrayerStats({
  required DateTime today,
  required Map<String, PrayerLog> logsByDay,
  required DateTime oldestLoaded,
  required Set<String> startedToday,
}) {
  final keys = PrayerLog.prayerKeys;
  final firstTracked = logsByDay.keys.isEmpty
      ? null
      : PrayerLog.parseDayKey(logsByDay.keys.reduce((a, b) => a.compareTo(b) <= 0 ? a : b));

  DateTime dayBefore(DateTime d, int n) => DateTime(d.year, d.month, d.day - n);
  PrayerStatus? statusOn(DateTime d, String key) => logsByDay[PrayerLog.dayKey(d)]?.statusFor(key);
  bool isDue(DateTime d, String key) =>
      statusOn(d, key) != PrayerStatus.excused && (d != today || startedToday.contains(key));

  // ---- Window counts
  var due = 0, prayed = 0, onTime = 0;
  final perDue = {for (final k in keys) k: 0};
  final perPrayed = {for (final k in keys) k: 0};
  final grid = {for (final k in keys) k: <PrayerStatus?>[]};

  for (var i = PrayerStats.windowDays - 1; i >= 0; i--) {
    final d = dayBefore(today, i);
    final tracked = firstTracked != null && !d.isBefore(firstTracked);
    for (final k in keys) {
      final status = statusOn(d, k);
      grid[k]!.add(tracked ? status : null);
      if (!tracked || !isDue(d, k)) continue;
      due++;
      perDue[k] = perDue[k]! + 1;
      if (status?.counted ?? false) {
        prayed++;
        perPrayed[k] = perPrayed[k]! + 1;
        if (status == PrayerStatus.onTime) onTime++;
      }
    }
  }

  int? pct(int n, int of) => of == 0 ? null : (n * 100 / of).round();
  final perPrayerPercent = {for (final k in keys) k: pct(perPrayed[k]!, perDue[k]!)};

  // ---- Streak
  var streak = 0;
  var capped = false;
  if (firstTracked != null) {
    for (var d = today; !d.isBefore(firstTracked); d = dayBefore(d, 1)) {
      final dueKeys = keys.where((k) => isDue(d, k)).toList();
      final complete = dueKeys.every((k) => statusOn(d, k)?.counted ?? false);
      if (d == today) {
        // An unfinished today neither adds nor breaks.
        if (complete && dueKeys.length == keys.length) streak++;
        continue;
      }
      if (dueKeys.isEmpty) continue; // fully excused: paused
      if (!complete) break;
      streak++;
      if (!d.isAfter(oldestLoaded)) {
        capped = true;
        break;
      }
    }
  }

  // ---- Weakest prayer: only called out when it's clearly behind the rest
  // and there's been at least a week of it to judge by.
  String? weakest;
  final judged = keys.where((k) => perDue[k]! >= 7).toList();
  if (judged.length == keys.length) {
    judged.sort((a, b) => perPrayerPercent[a]!.compareTo(perPrayerPercent[b]!));
    final low = judged.first;
    final others = judged.skip(1).map((k) => perPrayerPercent[k]!).toList();
    final othersAvg = others.reduce((a, b) => a + b) / others.length;
    if (perPrayerPercent[low]! < 80 && othersAvg - perPrayerPercent[low]! >= 10) weakest = low;
  }

  return PrayerStats(
    streak: streak,
    streakCapped: capped,
    prayedPercent: pct(prayed, due),
    onTimePercent: pct(onTime, prayed),
    perPrayerPercent: perPrayerPercent,
    grid: grid,
    weakestPrayer: weakest,
  );
}
