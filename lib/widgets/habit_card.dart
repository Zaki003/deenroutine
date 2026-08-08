import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  String _frequencyLabel() {
    if (habit.frequency == HabitFrequency.specificDays) {
      if (habit.selectedDays.isEmpty) return 'specificDays';
      final sorted = [...habit.selectedDays]..sort();
      return sorted.map((d) => kWeekdayShortNames[d]).join(', ');
    }
    return habit.frequency.name;
  }

  @override
  Widget build(BuildContext context) {
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
            Text('${habit.category.name} • ${_frequencyLabel()}'),
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
                    '🔥 $streak day streak',
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
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}