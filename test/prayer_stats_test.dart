import 'package:deenroutine/models/prayer_log.dart';
import 'package:deenroutine/utils/prayer_stats.dart';
import 'package:flutter_test/flutter_test.dart';

const _on = PrayerStatus.onTime;
const _late = PrayerStatus.late;
const _qada = PrayerStatus.qada;
const _ex = PrayerStatus.excused;
const _all = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};

void main() {
  final today = DateTime(2026, 9, 25);
  final oldest = DateTime(2026, 6, 28);
  DateTime ago(int n) => DateTime(today.year, today.month, today.day - n);

  PrayerLog log(DateTime day, List<PrayerStatus?> s) => PrayerLog(
        uid: 'u',
        day: PrayerLog.dayKey(day),
        statuses: {
          for (var i = 0; i < 5; i++)
            if (s[i] != null) PrayerLog.prayerKeys[i]: s[i]!,
        },
      );

  PrayerStats stats(List<PrayerLog> logs, {Set<String> started = _all}) => computePrayerStats(
        today: today,
        logsByDay: {for (final l in logs) l.day: l},
        oldestLoaded: oldest,
        startedToday: started,
      );

  test('days before tracking started are not counted as missed', () {
    final s = stats([log(ago(1), [_on, _on, _on, _on, _on])], started: {});
    expect(s.prayedPercent, 100);
    expect(s.grid['Fajr']!.where((x) => x != null).length, 1);
  });

  test('an unlogged prayer after tracking started counts as not prayed', () {
    final s = stats([
      log(ago(1), [_on, _on, _on, _on, _on]),
      log(today, [_on, null, null, null, null]),
    ], started: {'Fajr', 'Dhuhr'});
    // 5 yesterday + Fajr and Dhuhr today are due; 6 prayed.
    expect(s.prayedPercent, (6 * 100 / 7).round());
  });

  test('on time is out of prayed, and qada counts as prayed', () {
    final s = stats([log(ago(1), [_on, _late, _qada, _on, null])], started: {});
    expect(s.prayedPercent, 80);
    expect(s.onTimePercent, 50);
  });

  test('streak skips fully excused days and an unfinished today', () {
    final s = stats([
      log(ago(4), [_on, _on, _on, _on, _on]),
      log(ago(3), [_ex, _ex, _ex, _ex, _ex]),
      log(ago(2), [_on, _late, _qada, _on, _on]),
      log(ago(1), [_on, _on, _on, _on, _on]),
      log(today, [_on, null, null, null, null]),
    ], started: {'Fajr'});
    expect(s.streak, 3);
    expect(s.streakCapped, isFalse);
  });

  test('a missed prayer breaks the streak', () {
    final s = stats([
      log(ago(2), [_on, _on, _on, _on, _on]),
      log(ago(1), [_on, _on, null, _on, _on]),
      log(today, [_on, _on, _on, _on, _on]),
    ]);
    expect(s.streak, 1);
  });

  test('excused prayers are left out of percentages', () {
    final s = stats([log(ago(1), [_on, _on, _ex, _ex, _ex])], started: {});
    expect(s.prayedPercent, 100);
    expect(s.perPrayerPercent['Asr'], isNull);
  });

  test('weakest prayer is only called out when clearly behind', () {
    final logs = [
      for (var i = 1; i <= 10; i++) log(ago(i), [i <= 5 ? _on : null, _on, _on, _on, _on]),
    ];
    expect(stats(logs, started: {}).weakestPrayer, 'Fajr');
    final even = [for (var i = 1; i <= 10; i++) log(ago(i), [_on, _on, _on, _on, _on])];
    expect(stats(even, started: {}).weakestPrayer, isNull);
  });
}
