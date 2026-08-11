import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../utils/app_theme.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  });

  Color _categoryColor(ColorScheme scheme) {
    switch (habit.category) {
      case HabitCategory.islam:
        return scheme.success;
      case HabitCategory.lifestyle:
        return scheme.accentAmber;
      case HabitCategory.learn:
        return scheme.accentBlue;
      case HabitCategory.work:
        return scheme.accentPurple;
    }
  }

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
    if (confirmed == true) onDelete();
  }

  String _frequencyLabel(AppLocalizations l10n) {
    if (habit.frequency == HabitFrequency.specificDays) {
      if (habit.selectedDays.isEmpty) return habit.frequency.label(l10n);
      final sorted = [...habit.selectedDays]..sort();
      final names = weekdayShortNames(l10n);
      return sorted.map((d) => names[d]).join(', ');
    }
    return habit.frequency.label(l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryColor = _categoryColor(Theme.of(context).colorScheme);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor.withValues(alpha: 0.15),
          child: Icon(Icons.circle, size: 12, color: categoryColor),
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            decoration: habit.isCompletedToday ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${habit.category.label(l10n)} • ${_frequencyLabel(l10n)}'),
            FutureBuilder<int>(
              // Re-fetched on every rebuild (e.g. right after toggling), which
              // is exactly when the streak needs to be fresh.
              future: context.read<HabitProvider>().streakFor(habit.habitId),
              builder: (context, snapshot) {
                final streak = snapshot.data ?? 0;
                if (streak < 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    l10n.habitStreakDays(streak),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: habit.isCompletedToday, onChanged: (_) => onToggle()),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, l10n),
            ),
          ],
        ),
      ),
    );
  }
}
