import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/date_format.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/habit_actions_menu.dart';
import '../../widgets/habit_checkbox.dart';
import '../../widgets/habit_template_sheet.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/week_picker.dart';

/// Dedicated Habits tab: every habit with its streak and this week's
/// completion; tap a card for edit/delete options.
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final habits = context.watch<HabitProvider>().habits;

    // Reorders the Sun-first weekday names to Mon-first single letters,
    // matching the week picker's display order.
    final sunFirst = weekdayShortNames(l10n);
    final monFirstLetters = [
      for (final i in [1, 2, 3, 4, 5, 6, 0]) sunFirst[i].substring(0, 1),
    ];

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.navHabits,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DeenColors.primaryText(dark),
                ),
              ),
              GestureDetector(
                onTap: () => showHabitTemplateSheet(context),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DeenColors.gold,
                  ),
                  child: const Icon(Icons.add, size: 18, color: DeenColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (habits.isEmpty)
            EmptyStateCard(
              icon: Icons.checklist_rounded,
              message: l10n.noHabitsYet,
              dark: dark,
            ),
          ..._onceSection(habits: habits, l10n: l10n, dark: dark),
          for (final category in HabitCategory.values)
            ..._categorySection(
              category: category,
              habits: habits
                  .where((h) => h.frequency != HabitFrequency.once)
                  .toList(),
              l10n: l10n,
              dark: dark,
              monFirstLetters: monFirstLetters,
            ),
        ],
      ),
    );
  }
}

/// One-off to-dos ([HabitFrequency.once]), pulled out of the category
/// grouping entirely and shown as their own section above every recurring
/// habit — put here because a to-do's urgency (overdue, due today, coming
/// up) matters more than what category it happens to be filed under.
/// Sorted soonest-due first so anything overdue floats to the very top;
/// same-day items keep pending ones ahead of ones already done.
List<Widget> _onceSection({
  required List<Habit> habits,
  required AppLocalizations l10n,
  required bool dark,
}) {
  final onceHabits =
      habits.where((h) => h.frequency == HabitFrequency.once).toList()
        ..sort((a, b) {
          final dateCompare =
              (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? b.createdAt);
          if (dateCompare != 0) return dateCompare;
          final aDone = a.isCompletedToday ? 1 : 0;
          final bDone = b.isCompletedToday ? 1 : 0;
          return aDone.compareTo(bDone);
        });
  if (onceHabits.isEmpty) return const [];
  return [
    Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Text(
        l10n.onceSectionTitle,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: DeenColors.textMuted(dark),
        ),
      ),
    ),
    for (final habit in onceHabits)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _HabitRow(habit: habit, dark: dark, monFirstLetters: const []),
      ),
  ];
}

/// A category's section label plus its habits, in existing relative order —
/// omitted entirely when the category has no habits, so an empty category
/// never shows a dangling header.
List<Widget> _categorySection({
  required HabitCategory category,
  required List<Habit> habits,
  required AppLocalizations l10n,
  required bool dark,
  required List<String> monFirstLetters,
}) {
  final categoryHabits = habits.where((h) => h.category == category).toList();
  if (categoryHabits.isEmpty) return const [];
  return [
    Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Text(
        category.label(l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: DeenColors.textMuted(dark),
        ),
      ),
    ),
    for (final habit in categoryHabits)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _HabitRow(
            habit: habit, dark: dark, monFirstLetters: monFirstLetters),
      ),
  ];
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final bool dark;
  final List<String> monFirstLetters;

  const _HabitRow(
      {required this.habit, required this.dark, required this.monFirstLetters});

  Future<void> _confirmTimerBypass(
      BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.timerBypassTitle),
        content: Text(l10n.timerBypassContent(habit.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.markAsDoneButton),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<HabitProvider>().logTimerProgress(habit,
          elapsedSeconds: habit.timerTargetMinutes * 60);
    }
  }

  Widget? _onceStatusTag(AppLocalizations l10n) {
    if (habit.isCompletedToday) return null;
    final String text;
    final Color color;
    if (habit.isOverdue) {
      text = l10n.onceOverdueTag;
      color = dark ? DeenColors.rustLight : DeenColors.rust;
    } else if (habit.isDueToday) {
      text = l10n.onceDueTodayTag;
      color = dark ? DeenColors.goldSoft : DeenColors.primary;
    } else {
      text =
          l10n.onceDueOnTag(formatShortDate(l10n.localeName, habit.dueDate!));
      color = DeenColors.textMuted(dark);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = habit.isCompletedToday;
    final isOnce = habit.frequency == HabitFrequency.once;
    // Habits not scheduled for today (specificDays that don't include today)
    // stay in the list — this is the full-management view — but read as
    // muted so it's clear at a glance they're not due. Edit/delete stay
    // reachable since Opacity doesn't affect hit-testing. A one-off to-do
    // uses its own rule instead of isDueToday: only a still-upcoming due
    // date is muted — an overdue one stays at full opacity since that's a
    // "needs attention", not a "not applicable today", state.
    final opacity = isOnce
        ? (done || habit.isOverdue || habit.isDueToday ? 1.0 : 0.5)
        : (habit.isDueToday ? 1.0 : 0.45);
    return Opacity(
      opacity: opacity,
      child: HabitActionsMenu(
        habit: habit,
        child: DeenCard(
          dark: dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Read-only until done for most types — this screen isn't
                  // a second way to complete a habit, only an escape hatch
                  // for undoing an accidental completion. Timer is the one
                  // exception: there's otherwise no way to mark it done
                  // without actually running the in-app timer, so its
                  // not-done state opens a bypass-confirm instead of doing
                  // nothing.
                  HabitCheckbox(
                    done: done,
                    dark: dark,
                    size: 24,
                    onTap: done
                        ? () =>
                            context.read<HabitProvider>().undoCompletion(habit)
                        : habit.trackingType == HabitTrackingType.timer
                            ? () => _confirmTimerBypass(context, l10n)
                            : () {},
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: DeenColors.primaryText(dark),
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor:
                            DeenColors.primaryText(dark).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  // A streak or a week of dots both describe a recurrence
                  // pattern a one-off to-do doesn't have — it gets a
                  // due-state tag instead, and no tag at all once done.
                  if (isOnce)
                    _onceStatusTag(l10n) ?? const SizedBox.shrink()
                  else
                    FutureBuilder<int>(
                      future: context.read<HabitProvider>().streakFor(habit),
                      builder: (context, snapshot) =>
                          StreakBadge(streak: snapshot.data ?? 0, dark: dark),
                    ),
                ],
              ),
              if (!isOnce) ...[
                const SizedBox(height: 8),
                FutureBuilder<List<bool>>(
                  future: context.read<HabitProvider>().weekFor(habit),
                  builder: (context, snapshot) {
                    final days = snapshot.data ?? List.filled(7, false);
                    return WeekPicker(
                        days: days, labels: monFirstLetters, dark: dark);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
