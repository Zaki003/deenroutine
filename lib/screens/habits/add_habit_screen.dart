import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleCtrl = TextEditingController();
  HabitCategory _category = HabitCategory.islam;
  HabitFrequency _frequency = HabitFrequency.daily;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('New Habit')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Habit title'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HabitCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: HabitCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HabitFrequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: HabitFrequency.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                  .toList(),
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_titleCtrl.text.trim().isEmpty) return;
                      setState(() => _saving = true);
                      await context.read<HabitProvider>().addHabit(
                            uid: uid,
                            title: _titleCtrl.text.trim(),
                            category: _category,
                            frequency: _frequency,
                          );
                      if (mounted) Navigator.pop(context);
                    },
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save Habit'),
            ),
          ],
        ),
      ),
    );
  }
}
