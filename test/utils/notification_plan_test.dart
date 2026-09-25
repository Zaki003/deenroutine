import 'package:deenroutine/l10n/app_localizations.dart';
import 'package:deenroutine/models/habit.dart';
import 'package:deenroutine/utils/habit_notification_text.dart';
import 'package:deenroutine/utils/notification_plan.dart';
import 'package:deenroutine/utils/week_stats.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pieces of the reminder/nudge system that can be checked without a
/// device: which ID belongs to which habit and day, which habits deserve a
/// streak nudge, when Friday's and the come-back messages land, and what the
/// wording rules produce. The scheduling itself (an alarm actually firing)
/// isn't covered here.
Habit habit({
  String id = 'h1',
  HabitFrequency frequency = HabitFrequency.daily,
  HabitTrackingType tracking = HabitTrackingType.yesNo,
  List<int> days = const [],
  bool doneToday = false,
  DateTime? dueDate,
}) =>
    Habit(
      habitId: id,
      uid: 'u',
      title: 'Read Qur\'an',
      category: HabitCategory.islam,
      frequency: frequency,
      trackingType: tracking,
      selectedDays: days,
      dueDate: dueDate,
      completed: doneToday,
      lastCompletedDate: doneToday ? DateTime.now() : null,
    );

void main() {
  group('stableHash', () {
    test('matches the published FNV-1a 32-bit values', () {
      expect(stableHash(''), 0x811c9dc5);
      expect(stableHash('a'), 0xe40c292c);
      expect(stableHash('foobar'), 0xbf9cf968);
    });
  });

  group('habit reminder IDs', () {
    final day = DateTime(2026, 9, 25);

    test('sit inside the habit band and are stable', () {
      final id = habitReminderId('abc123', day);
      expect(isHabitReminderId(id), isTrue);
      expect(habitReminderId('abc123', day), id);
      expect(habitReminderId('abc123', DateTime(2026, 9, 25, 20, 30)), id);
    });

    test('never collide across a 7-day window', () {
      final ids = {
        for (var i = 0; i < kReminderWindowDays; i++)
          habitReminderId('abc123', DateTime(2026, 9, 25 + i)),
      };
      expect(ids.length, kReminderWindowDays);
    });

    test('differ between habits', () {
      expect(habitReminderId('habit-a', day), isNot(habitReminderId('habit-b', day)));
    });

    test("keep a to-do's reminder apart from the daily window", () {
      final windowIds = {
        for (var i = 0; i < 8; i++) habitReminderId('abc123', DateTime(2026, 9, 25 + i)),
      };
      expect(windowIds.contains(habitOneOffReminderId('abc123')), isFalse);
    });

    test('allHabitReminderIds covers everything a habit can own', () {
      final all = allHabitReminderIds('abc123');
      expect(all.length, 16);
      expect(all.every(isHabitReminderId), isTrue);
      expect(all, contains(habitReminderId('abc123', day)));
      expect(all, contains(habitOneOffReminderId('abc123')));
    });

    test('stay clear of the quote band and the single-slot nudges', () {
      final all = allHabitReminderIds('abc123');
      expect(all.every((id) => id < 2000000000), isTrue);
      expect(singleSlotNudgeIds.every((id) => !isHabitReminderId(id)), isTrue);
    });
  });

  group('pickRotating', () {
    final bank = ['a', 'b', 'c', 'd', 'e', 'f'];

    test('is stable for the same habit and day', () {
      final day = DateTime(2026, 9, 25);
      expect(pickRotating(bank, 'h1', day), pickRotating(bank, 'h1', day));
    });

    test('changes from day to day', () {
      final picks = {
        for (var i = 0; i < 6; i++)
          pickRotating(bank, 'h1', DateTime(2026, 9, 25 + i)),
      };
      expect(picks.length, 6);
    });
  });

  group('skipReminderToday', () {
    test('skips a habit already done today', () {
      expect(skipReminderToday(habit(doneToday: true)), isTrue);
    });

    test("doesn't skip one that isn't done", () {
      expect(skipReminderToday(habit()), isFalse);
    });

    test("never skips an avoidance habit - silence is its success", () {
      expect(
        skipReminderToday(
            habit(tracking: HabitTrackingType.avoidance, doneToday: true)),
        isFalse,
      );
    });
  });

  group('Habit.isDueOn', () {
    test('daily habits are due every day', () {
      expect(habit().isDueOn(DateTime(2026, 9, 26)), isTrue);
    });

    test('specific days follow the Sun=0 numbering', () {
      final monWed = habit(frequency: HabitFrequency.specificDays, days: [1, 3]);
      expect(monWed.isDueOn(DateTime(2026, 9, 21)), isTrue); // Monday
      expect(monWed.isDueOn(DateTime(2026, 9, 22)), isFalse); // Tuesday
      final sunday = habit(frequency: HabitFrequency.specificDays, days: [0]);
      expect(sunday.isDueOn(DateTime(2026, 9, 27)), isTrue); // Sunday
    });

    test('a to-do is due only on its due date', () {
      final todo =
          habit(frequency: HabitFrequency.once, dueDate: DateTime(2026, 9, 25));
      expect(todo.isDueOn(DateTime(2026, 9, 25, 18)), isTrue);
      expect(todo.isDueOn(DateTime(2026, 9, 26)), isFalse);
    });
  });

  group('streak nudge', () {
    test('goes out today if the time is still ahead, tomorrow if not', () {
      expect(
        nextStreakNudgeTime(DateTime(2026, 9, 25, 15, 0), hour: 20, minute: 0),
        DateTime(2026, 9, 25, 20, 0),
      );
      expect(
        nextStreakNudgeTime(DateTime(2026, 9, 25, 21, 0), hour: 20, minute: 0),
        DateTime(2026, 9, 26, 20, 0),
      );
      expect(
        nextStreakNudgeTime(DateTime(2026, 9, 25, 20, 0), hour: 20, minute: 0),
        DateTime(2026, 9, 26, 20, 0),
      );
    });

    group('candidates', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 20);
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 20);

      test('a plain recurring habit that is not done qualifies', () {
        expect(isStreakNudgeCandidate(habit(), today, now), isTrue);
      });

      test('a to-do never does', () {
        expect(
          isStreakNudgeCandidate(habit(frequency: HabitFrequency.once), today, now),
          isFalse,
        );
      });

      test('an avoidance habit never does', () {
        expect(
          isStreakNudgeCandidate(
              habit(tracking: HabitTrackingType.avoidance), today, now),
          isFalse,
        );
      });

      test("one that isn't due that day doesn't", () {
        final notDue = habit(
          frequency: HabitFrequency.specificDays,
          days: [(today.weekday + 1) % 7],
        );
        expect(isStreakNudgeCandidate(notDue, today, now), isFalse);
      });

      test("today's is dropped once the habit is done, tomorrow's is not", () {
        final done = habit(doneToday: true);
        expect(isStreakNudgeCandidate(done, today, now), isFalse);
        expect(isStreakNudgeCandidate(done, tomorrow, now), isTrue);
      });
    });

    group('pickStreakNudge', () {
      final a = habit(id: 'a');
      final b = habit(id: 'b');

      test('ignores streaks too short to be worth protecting', () {
        expect(pickStreakNudge([(habit: a, streak: 2)]), isNull);
      });

      test('picks the longest', () {
        final pick = pickStreakNudge([(habit: a, streak: 4), (habit: b, streak: 9)]);
        expect(pick?.habit.habitId, 'b');
        expect(pick?.streak, 9);
      });

      test('the first wins a tie', () {
        final pick = pickStreakNudge([(habit: a, streak: 5), (habit: b, streak: 5)]);
        expect(pick?.habit.habitId, 'a');
      });

      test('nothing to pick from is nothing', () {
        expect(pickStreakNudge([]), isNull);
      });
    });
  });

  group('weekly summary time', () {
    test('a Monday looks ahead to that week\'s Friday', () {
      expect(nextWeeklySummaryTime(DateTime(2026, 9, 21, 10)),
          DateTime(2026, 9, 25, 17));
    });

    test('a Friday before the time is today', () {
      expect(nextWeeklySummaryTime(DateTime(2026, 9, 25, 10)),
          DateTime(2026, 9, 25, 17));
    });

    test('a Friday after the time is next week', () {
      expect(nextWeeklySummaryTime(DateTime(2026, 9, 25, 18)),
          DateTime(2026, 10, 2, 17));
    });

    test('a Saturday is next week', () {
      expect(nextWeeklySummaryTime(DateTime(2026, 9, 26, 10)),
          DateTime(2026, 10, 2, 17));
    });
  });

  group('isSameWeek', () {
    test('runs Monday to Sunday', () {
      expect(isSameWeek(DateTime(2026, 9, 21), DateTime(2026, 9, 27, 23, 59)), isTrue);
      expect(isSameWeek(DateTime(2026, 9, 20), DateTime(2026, 9, 21)), isFalse);
    });
  });

  group('comebackTimes', () {
    test('are 4 and 10 days out', () {
      expect(comebackTimes(DateTime(2026, 9, 25, 9)), [
        DateTime(2026, 9, 29, 18),
        DateTime(2026, 10, 5, 18),
      ]);
    });

    test('roll over month ends', () {
      expect(comebackTimes(DateTime(2026, 9, 28, 9)), [
        DateTime(2026, 10, 2, 18),
        DateTime(2026, 10, 8, 18),
      ]);
    });
  });

  group('computeWeekStats', () {
    List<bool> week(List<int> doneDays) =>
        [for (var i = 0; i < 7; i++) doneDays.contains(i)];

    test('adds up days, totals and the best habit', () {
      final stats = computeWeekStats([week([0, 1, 2]), week([1]), week([])]);
      expect(stats.dayCounts, [1, 2, 1, 0, 0, 0, 0]);
      expect(stats.totalDone, 4);
      expect(stats.totalPossible, 21);
      expect(stats.bestIndex, 0);
      expect(stats.bestCount, 3);
    });

    test('the first habit wins a tie', () {
      final stats = computeWeekStats([week([0, 1]), week([2, 3])]);
      expect(stats.bestIndex, 0);
    });

    test('an empty week has no best habit', () {
      final stats = computeWeekStats([week([]), week([])]);
      expect(stats.bestIndex, -1);
      expect(stats.totalDone, 0);
    });

    test('no habits at all is all zeros', () {
      final stats = computeWeekStats([]);
      expect(stats.totalPossible, 0);
      expect(stats.dayCounts, everyElement(0));
    });
  });

  group('notification wording', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final bn = lookupAppLocalizations(const Locale('bn'));
    final doBank = [
      en.reminderMsgDo1,
      en.reminderMsgDo2,
      en.reminderMsgDo3,
      en.reminderMsgDo4,
      en.reminderMsgDo5,
      en.reminderMsgDo6,
    ];
    final avoidBank = [
      en.reminderMsgAvoid1,
      en.reminderMsgAvoid2,
      en.reminderMsgAvoid3,
    ];
    final day = DateTime(2026, 9, 25);

    test('encouraging reminders title the habit and rotate a message', () {
      final text = habitReminderText(en, habit(), day, encouraging: true);
      expect(text.title, "Read Qur'an");
      expect(doBank, contains(text.body));
      final bodies = {
        for (var i = 0; i < 6; i++)
          habitReminderText(en, habit(), DateTime(2026, 9, 25 + i),
                  encouraging: true)
              .body,
      };
      expect(bodies.length, greaterThan(1));
    });

    test('plain reminders keep the original wording', () {
      final text = habitReminderText(en, habit(), day, encouraging: false);
      expect(text.title, en.reminderNotificationTitle);
      expect(text.body, en.reminderNotificationBody("Read Qur'an"));
    });

    test('an avoidance habit only ever gets the supportive wording', () {
      final avoidance = habit(tracking: HabitTrackingType.avoidance);
      for (var i = 0; i < 10; i++) {
        final text = habitReminderText(en, avoidance, DateTime(2026, 9, 25 + i),
            encouraging: true);
        expect(avoidBank, contains(text.body));
        expect(doBank, isNot(contains(text.body)));
      }
    });

    test('the streak nudge names the habit and the streak', () {
      final text = streakNudgeText(en, habit(), 12);
      expect(text.title, contains('12'));
      expect(text.body, contains("Read Qur'an"));
    });

    test('the Friday summary uses numbers only when there is something to say',
        () {
      final withStats = weeklySummaryText(en, done: 7, bestHabit: 'Fajr');
      expect(withStats.body, contains('7'));
      expect(withStats.body, contains('Fajr'));

      final empty = weeklySummaryText(en, done: 0, bestHabit: null);
      final unknown = weeklySummaryText(en, done: null, bestHabit: null);
      expect(empty.body, en.weeklySummaryNotificationBodyGeneric);
      expect(unknown.body, en.weeklySummaryNotificationBodyGeneric);
    });

    test('the two come-back messages differ, in both languages', () {
      for (final l10n in [en, bn]) {
        final first = comebackText(l10n, second: false);
        final second = comebackText(l10n, second: true);
        expect(first.body, isNot(second.body));
        expect(first.title, isNot(second.title));
      }
    });
  });
}
