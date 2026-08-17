import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../screens/habits/add_habit_screen.dart';

enum _HabitAction { edit, delete }

/// Wraps a habit card so tapping it opens an Edit/Delete menu, instead of
/// tapping straight through to the edit screen with no way to delete.
class HabitActionsMenu extends StatelessWidget {
  final Habit habit;
  final Widget child;

  const HabitActionsMenu({super.key, required this.habit, required this.child});

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
    final errorColor = Theme.of(context).colorScheme.error;

    return PopupMenuButton<_HabitAction>(
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) {
        if (action == _HabitAction.edit) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddHabitScreen(editingHabit: habit)),
          );
        } else {
          _confirmDelete(context, l10n);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _HabitAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.editButton),
          ),
        ),
        PopupMenuItem(
          value: _HabitAction.delete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: errorColor),
            title: Text(l10n.deleteButton, style: TextStyle(color: errorColor)),
          ),
        ),
      ],
      child: child,
    );
  }
}
