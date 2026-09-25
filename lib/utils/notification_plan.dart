import '../models/habit.dart';
import 'daily_quote_schedule.dart' show quoteEpoch;

// ---- Notification ID bands (all int32) -----------------------------------
//
// Habit reminders used to be `title.hashCode` (always below 2^30). Every band
// below sits above that, so cancelling one kind never touches another, and
// the prayer alarms' small fixed IDs are nowhere near any of them.
//
//   1_100_000_000 .. 1_900_000_000   per-habit reminders (see [habitReminderId])
//   2_000_000_000 .. 2_000_000_006   daily ayah/hadith (NotificationService)
//   2_000_000_100 .. 2_000_000_103   the single-slot nudges below
//   2_000_000_200 .. 2_000_000_209   prayer check-ins (prayer_check_in_plan.dart)

const int habitReminderIdMin = 1100000000;
const int habitReminderIdMax = 1900000000; // exclusive
const int streakNudgeId = 2000000100;
const int weeklySummaryId = 2000000101;
const int comebackFirstId = 2000000102;
const int comebackSecondId = 2000000103;
const Set<int> singleSlotNudgeIds = {
  streakNudgeId,
  weeklySummaryId,
  comebackFirstId,
  comebackSecondId,
};

/// Each habit owns [_slotsPerHabit] consecutive IDs: 8 rotating slots for its
/// reminder window (one per calendar day, `dayNumber % 8`, so any 7 days in a
/// row never collide) and one for a to-do's single reminder.
const int _slotsPerHabit = 16;
const int _rotatingSlots = 8;
const int _oneOffSlot = 8;
const int _habitBuckets = 50000000;

/// How many days ahead a habit's reminders are scheduled.
const int kReminderWindowDays = 7;

/// A streak has to be at least this long before losing it is worth a nudge.
const int kStreakNudgeMinDays = 3;

/// Fixed times for the nudges the user doesn't pick a time for.
const int kWeeklySummaryHour = 17;
const int kComebackHour = 18;

/// 32-bit FNV-1a. Unlike `String.hashCode`, its value is defined by the
/// algorithm rather than the current Dart SDK, which matters because these
/// IDs must come out identical on every launch to cancel what a previous
/// launch scheduled.
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// Whole days between the quote epoch and [d]'s local calendar date.
int localDayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(quoteEpoch).inDays;

int _habitBase(String habitId) =>
    habitReminderIdMin +
    (stableHash(habitId) % _habitBuckets) * _slotsPerHabit;

/// ID of [habitId]'s reminder on [date]. Stable per (habit, calendar day), so
/// rescheduling replaces the same notification and "skip today" can cancel
/// exactly today's.
int habitReminderId(String habitId, DateTime date) =>
    _habitBase(habitId) + localDayNumber(date) % _rotatingSlots;

int habitOneOffReminderId(String habitId) => _habitBase(habitId) + _oneOffSlot;

/// Every ID a habit could own - what to cancel when it's deleted.
List<int> allHabitReminderIds(String habitId) =>
    [for (var s = 0; s < _slotsPerHabit; s++) _habitBase(habitId) + s];

bool isHabitReminderId(int id) =>
    id >= habitReminderIdMin && id < habitReminderIdMax;

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Picks from [bank] so consecutive days differ and different habits don't
/// all land on the same line on the same day.
T pickRotating<T>(List<T> bank, String habitId, DateTime date) =>
    bank[(localDayNumber(date) + stableHash(habitId)) % bank.length];

/// Whether today's reminder for [habit] should be skipped because it's
/// already done. An avoidance habit is never "done" in that sense - a slip is
/// the only thing it ever logs - so it keeps its reminder.
bool skipReminderToday(Habit habit) =>
    habit.trackingType != HabitTrackingType.avoidance && habit.isCompletedToday;

// ---- Streak nudge --------------------------------------------------------

/// The next time the evening nudge would fire: today at [hour]:[minute] if
/// that's still ahead, otherwise tomorrow.
DateTime nextStreakNudgeTime(DateTime now,
    {required int hour, required int minute}) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return today.isAfter(now)
      ? today
      : DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// Whether [habit] could have a streak worth protecting on [day]: a
/// recurring, do-something habit that's due that day and (for today) isn't
/// already done. To-dos have no streak, and avoidance habits succeed by
/// silence, so a "you haven't done it" nudge would be meaningless - or worse,
/// read as a reproach.
bool isStreakNudgeCandidate(Habit habit, DateTime day, DateTime now) {
  if (habit.frequency == HabitFrequency.once) return false;
  if (habit.trackingType == HabitTrackingType.avoidance) return false;
  if (!habit.isDueOn(day)) return false;
  if (isSameDay(day, now) && habit.isCompletedToday) return false;
  return true;
}

/// The habit with the longest streak of at least [kStreakNudgeMinDays]; the
/// first one wins a tie.
({Habit habit, int streak})? pickStreakNudge(
    List<({Habit habit, int streak})> candidates) {
  ({Habit habit, int streak})? best;
  for (final c in candidates) {
    if (c.streak < kStreakNudgeMinDays) continue;
    if (best == null || c.streak > best.streak) best = c;
  }
  return best;
}

// ---- Weekly summary and come-back -----------------------------------------

/// The next Friday at [hour]:[minute] - today's if it's Friday and that time
/// is still ahead.
DateTime nextWeeklySummaryTime(DateTime now,
    {int hour = kWeeklySummaryHour, int minute = 0}) {
  final daysUntilFriday = (DateTime.friday - now.weekday) % 7;
  final thisFriday = DateTime(
      now.year, now.month, now.day + daysUntilFriday, hour, minute);
  return thisFriday.isAfter(now)
      ? thisFriday
      : DateTime(thisFriday.year, thisFriday.month, thisFriday.day + 7, hour, minute);
}

DateTime mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

bool isSameWeek(DateTime a, DateTime b) => isSameDay(mondayOf(a), mondayOf(b));

/// When the two come-back messages would fire if the app isn't opened again:
/// 4 and 10 days out. Both are rescheduled on every launch, so they only ever
/// fire for someone who really has gone quiet - and there are only two of
/// them, so it stops there without needing a counter.
List<DateTime> comebackTimes(DateTime now, {int hour = kComebackHour}) => [
      DateTime(now.year, now.month, now.day + 4, hour),
      DateTime(now.year, now.month, now.day + 10, hour),
    ];
