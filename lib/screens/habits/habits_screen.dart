import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/habit_actions_menu.dart';
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
    final habits = _sortedByCategory(context.watch<HabitProvider>().habits);

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.noHabitsYet,
                  style: const TextStyle(color: DeenColors.textMuted)),
            ),
          for (final habit in habits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HabitRow(habit: habit, dark: dark, monFirstLetters: monFirstLetters),
            ),
        ],
      ),
    );
  }
}

/// Groups habits by category — in [HabitCategory]'s declared order (Islam,
/// Lifestyle, Learn, Work) — while keeping each category's habits in their
/// existing relative order.
List<Habit> _sortedByCategory(List<Habit> habits) => [
      for (final category in HabitCategory.values)
        ...habits.where((h) => h.category == category),
    ];

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final bool dark;
  final List<String> monFirstLetters;

  const _HabitRow({required this.habit, required this.dark, required this.monFirstLetters});

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday;
    return HabitActionsMenu(
      habit: habit,
      child: DeenCard(
        dark: dark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  future: context.read<HabitProvider>().streakFor(habit.habitId),
                  builder: (context, snapshot) =>
                      StreakBadge(streak: snapshot.data ?? 0, dark: dark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<bool>>(
              future: context.read<HabitProvider>().weekFor(habit.habitId),
              builder: (context, snapshot) {
                final days = snapshot.data ?? List.filled(7, false);
                return WeekPicker(days: days, labels: monFirstLetters, dark: dark);
              },
            ),
          ],
        ),
      ),
    );
  }
}
