import 'package:flutter/material.dart';
import '../models/habit.dart';

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

  Color _categoryColor() {
    switch (habit.category) {
      case HabitCategory.islam:
        return const Color(0xFF2E7D32);
      case HabitCategory.lifestyle:
        return Colors.orange;
      case HabitCategory.learn:
        return Colors.blue;
      case HabitCategory.work:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _categoryColor().withOpacity(0.15),
          child: Icon(Icons.circle, size: 12, color: _categoryColor()),
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            decoration: habit.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${habit.category.name} • ${habit.frequency.name}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: habit.completed, onChanged: (_) => onToggle()),
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
