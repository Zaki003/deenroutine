import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import 'notification_plan.dart';

/// Wording for the habit-related notifications. Plain strings out, no
/// BuildContext - callers hand in whichever [AppLocalizations] matches the
/// language the text should be baked in as.
///
/// Tone rules the wording follows: encouraging, never shaming; nothing about
/// slips for an avoidance habit; and a verse or hadith is only used where
/// it's about patience or consistency, never fear or punishment.
typedef NotificationText = ({String title, String body});

List<String> _reminderBodies(AppLocalizations l10n, {required bool avoidance}) =>
    avoidance
        ? [l10n.reminderMsgAvoid1, l10n.reminderMsgAvoid2, l10n.reminderMsgAvoid3]
        : [
            l10n.reminderMsgDo1,
            l10n.reminderMsgDo2,
            l10n.reminderMsgDo3,
            l10n.reminderMsgDo4,
            l10n.reminderMsgDo5,
            l10n.reminderMsgDo6,
          ];

/// A recurring habit's reminder for [date]. Encouraging mode titles it with
/// the habit and rotates a short message; plain mode is the original
/// "Time for: ..." line.
NotificationText habitReminderText(
  AppLocalizations l10n,
  Habit habit,
  DateTime date, {
  required bool encouraging,
}) {
  if (!encouraging) {
    return (
      title: l10n.reminderNotificationTitle,
      body: l10n.reminderNotificationBody(habit.title),
    );
  }
  final bank = _reminderBodies(l10n,
      avoidance: habit.trackingType == HabitTrackingType.avoidance);
  return (title: habit.title, body: pickRotating(bank, habit.habitId, date));
}

NotificationText streakNudgeText(
        AppLocalizations l10n, Habit habit, int streak) =>
    (
      title: l10n.streakNudgeNotificationTitle(streak),
      body: l10n.streakNudgeNotificationBody(habit.title),
    );

/// The Friday summary. Numbers are only used when there's something to
/// celebrate; an empty week gets the number-free wording rather than a "0".
NotificationText weeklySummaryText(
  AppLocalizations l10n, {
  required int? done,
  required String? bestHabit,
}) {
  final hasStats = done != null && done > 0 && bestHabit != null;
  return (
    title: l10n.weeklySummaryNotificationTitle,
    body: hasStats
        ? l10n.weeklySummaryNotificationBodyStats(done, bestHabit)
        : l10n.weeklySummaryNotificationBodyGeneric,
  );
}

NotificationText comebackText(AppLocalizations l10n, {required bool second}) =>
    second
        ? (
            title: l10n.comebackSecondNotificationTitle,
            body: l10n.comebackSecondNotificationBody,
          )
        : (
            title: l10n.comebackNotificationTitle,
            body: l10n.comebackNotificationBody,
          );
