import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/deen_colors.dart';
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
          for (final category in HabitCategory.values)
            ..._categorySection(
              category: category,
              habits: habits,
              l10n: l10n,
              dark: dark,
              monFirstLetters: monFirstLetters,
            ),
        ],
      ),
    );
  }
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
        child: _HabitRow(habit: habit, dark: dark, monFirstLetters: monFirstLetters),
      ),
  ];
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final bool dark;
  final List<String> monFirstLetters;

  const _HabitRow({required this.habit, required this.dark, required this.monFirstLetters});

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday;
    // Habits not scheduled for today (specificDays that don't include today)
    // stay in the list — this is the full-management view — but read as
    // muted so it's clear at a glance they're not due. Edit/delete stay
    // reachable since Opacity doesn't affect hit-testing.
    return Opacity(
      opacity: habit.isDueToday ? 1 : 0.45,
      child: HabitActionsMenu(
        habit: habit,
        child: DeenCard(
          dark: dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Read-only until done: this screen isn't a second way to
                  // complete a habit, only an escape hatch for undoing an
                  // accidental completion, so an outline circle here is
                  // just today's status at a glance and doesn't respond to
                  // a tap — only the filled/tappable done state does.
                  HabitCheckbox(
                    done: done,
                    dark: dark,
                    size: 24,
                    onTap: done
                        ? () => context.read<HabitProvider>().undoCompletion(habit)
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
                        decorationColor: DeenColors.primaryText(dark).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  FutureBuilder<int>(
                    future: context.read<HabitProvider>().streakFor(habit),
                    builder: (context, snapshot) =>
                        StreakBadge(streak: snapshot.data ?? 0, dark: dark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<bool>>(
                future: context.read<HabitProvider>().weekFor(habit),
                builder: (context, snapshot) {
                  final days = snapshot.data ?? List.filled(7, false);
                  return WeekPicker(days: days, labels: monFirstLetters, dark: dark);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
