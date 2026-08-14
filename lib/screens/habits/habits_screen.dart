import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/week_picker.dart';
import 'add_habit_screen.dart';

/// Dedicated Habits tab: every habit with its streak and this week's
/// completion, tap to edit, long-press to delete.
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                ),
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

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final bool dark;
  final List<String> monFirstLetters;

  const _HabitRow({required this.habit, required this.dark, required this.monFirstLetters});

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteHabitTitle),
        content: Text(l10n.deleteHabitContent(habit.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.deleteButton,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<HabitProvider>().deleteHabit(habit.habitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddHabitScreen(editingHabit: habit)),
      ),
      onLongPress: () => _confirmDelete(context, l10n),
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
