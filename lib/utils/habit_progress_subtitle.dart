import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import 'duration_format.dart';

/// The small muted line shown under a habit's title on the dashboard row,
/// e.g. "6/10 pages" or "3:12 left". Returns null when there's nothing
/// useful to report yet — yesNo/avoidance never have progress detail beyond
/// the tap itself, and an unrated rating habit has nothing to show until
/// it's actually rated.
String? habitProgressSubtitle(AppLocalizations l10n, Habit habit) {
  switch (habit.trackingType) {
    case HabitTrackingType.numeric:
      final current = habit.hasProgressToday ? habit.todayProgressValue : 0;
      final unit = habit.numericUnit.trim().isEmpty ? l10n.numericUnitDefault : habit.numericUnit;
      return l10n.numericProgressSubtitle(current, habit.numericTarget, unit);
    case HabitTrackingType.timer:
      final elapsed = habit.hasProgressToday ? habit.todayProgressValue : 0;
      final targetSeconds = habit.timerTargetMinutes * 60;
      final remaining = (targetSeconds - elapsed).clamp(0, targetSeconds);
      return l10n.timerProgressSubtitle(formatMmSs(Duration(seconds: remaining)));
    case HabitTrackingType.checklist:
      final total = habit.checklistItems.length;
      final doneItems = habit.hasProgressToday ? habit.todayChecklistDone : const <String>[];
      final doneCount = doneItems.where(habit.checklistItems.contains).length;
      return l10n.checklistProgressSubtitle(doneCount, total);
    case HabitTrackingType.rating:
      final rated = habit.hasProgressToday ? habit.todayRatingValue : null;
      if (rated == null) return null;
      return l10n.ratingProgressSubtitle(rated, habit.ratingScale);
    case HabitTrackingType.yesNo:
    case HabitTrackingType.avoidance:
      return null;
  }
}
