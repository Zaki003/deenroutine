import 'package:deenroutine/models/habit.dart';
import 'package:deenroutine/models/habit_log.dart';
import 'package:deenroutine/utils/habit_insights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A Friday; the grid's current week runs Mon 21 - Sun 27 September.
  final now = DateTime(2026, 9, 25, 14);
  DateTime d(int month, int day) => DateTime(2026, month, day);

  Habit habit(
    String id, {
    required DateTime created,
    HabitTrackingType type = HabitTrackingType.yesNo,
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> days = const [],
  }) =>
      Habit(
        habitId: id,
        uid: 'u',
        title: id,
        category: HabitCategory.islam,
        frequency: frequency,
        selectedDays: days,
        trackingType: type,
        createdAt: created,
      );

  HabitLog log(String habitId, DateTime day, {bool status = true}) =>
      HabitLog(logId: '$habitId-$day', habitId: habitId, uid: 'u', date: day, status: status);

  HabitInsights run(List<Habit> habits, Map<String, List<HabitLog>> logs) => computeHabitInsights(
        habits: habits,
        logsByHabit: logs,
        now: now,
        currentStreak: (h, l) => 0,
      );

  test('the grid is four Mon-Sun weeks, with days not yet come left empty', () {
    final h = habit('quran', created: d(8, 1));
    final i = run([h], {'quran': [log('quran', d(9, 24))]});
    expect(i.grid.length, 28);
    // The grid starts Mon 31 Aug, so index 21 is Mon 21 Sep.
    expect(i.grid[21 + 3], 1.0); // Thu 24th, done
    expect(i.grid[21 + 2], 0.0); // Wed 23rd, due but not done
    expect(i.grid[21 + 5], isNull); // Sat 26th, hasn't come yet
  });

  test('days before a habit existed are neither due nor counted', () {
    final h = habit('quran', created: d(9, 24));
    final i = run([h], {'quran': [log('quran', d(9, 24))]});
    expect(i.grid[0], isNull);
    expect(i.ratePercent, 100); // only the 24th counts; today is excluded
  });

  test('a specific-days habit is only due on its days', () {
    // Mondays and Thursdays (weekday % 7 = 1 and 4).
    final h = habit('fast', created: d(8, 1), frequency: HabitFrequency.specificDays, days: [1, 4]);
    final i = run([h], {'fast': [log('fast', d(9, 21)), log('fast', d(9, 24))]});
    expect(i.grid[21 + 1], isNull); // Tuesday isn't a fasting day
    expect(i.weekDue, 2);
    expect(i.weekDone, 2);
  });

  test('avoidance: silence is the win, a slip is the loss, and neither is a check-in', () {
    final h = habit('social', created: d(9, 21), type: HabitTrackingType.avoidance);
    final i = run([h], {'social': [log('social', d(9, 23), status: false)]});
    expect(i.grid[21 + 1], 1.0); // no slip on the 22nd
    expect(i.grid[21 + 2], 0.0); // slipped on the 23rd
    expect(i.checkIns, 0);
  });

  test('milestones come from the longest streak ever, so they stay earned', () {
    final h = habit('quran', created: d(8, 1));
    final logs = [
      for (var day = 1; day <= 31; day++) log('quran', d(8, day)), // 31 days in August
      log('quran', d(9, 24)), // then a gap, and a fresh start
    ];
    final i = run([h], {'quran': logs});
    expect(i.longestEver, 31);
    expect(i.reached(30), isTrue);
    expect(i.reached(40), isFalse);
    expect(i.checkIns, 32);
  });

  test('today not being done yet does not end a run', () {
    final h = habit('quran', created: d(9, 18));
    final logs = [for (var day = 18; day <= 24; day++) log('quran', d(9, day))];
    expect(run([h], {'quran': logs}).longestEver, 7);
  });

  test('one-off to-dos are left out', () {
    final h = habit('todo', created: d(9, 1), frequency: HabitFrequency.once);
    final i = run([h], {'todo': [log('todo', d(9, 24))]});
    expect(i.checkIns, 0);
    expect(i.weekDue, 0);
  });
}
