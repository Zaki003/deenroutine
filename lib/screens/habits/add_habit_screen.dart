import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/notification_service.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  HabitCategory _category = HabitCategory.islam;
  HabitFrequency _frequency = HabitFrequency.daily;
  TimeOfDay? _reminderTime;
  bool _saving = false;

  /// Selected day indices for HabitFrequency.specificDays, using the
  /// S M T W T F S order (0=Sun ... 6=Sat) defined in kWeekdayLetters.
  final Set<int> _selectedDays = {};
  String? _dayPickerError;

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Widget _buildDayPicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Repeat on', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final selected = _selectedDays.contains(index);
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedDays.remove(index);
                    } else {
                      _selectedDays.add(index);
                    }
                    _dayPickerError = null;
                  });
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: selected
                      ? const Color(0xFF2E7D32)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    kWeekdayLetters[index],
                    style: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_dayPickerError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _dayPickerError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('New Habit')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Habit title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: HabitCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitFrequency>(
                value: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: HabitFrequency.values
                    .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _frequency = v!;
                  if (_frequency != HabitFrequency.specificDays) {
                    _selectedDays.clear();
                    _dayPickerError = null;
                  }
                }),
              ),
              if (_frequency == HabitFrequency.specificDays) _buildDayPicker(),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Daily reminder'),
                subtitle: Text(
                  _reminderTime == null
                      ? 'Off — tap to set a time'
                      : 'At ${_reminderTime!.format(context)}',
                ),
                trailing: _reminderTime == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _reminderTime = null),
                      ),
                onTap: _pickReminderTime,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        if (_frequency == HabitFrequency.specificDays &&
                            _selectedDays.isEmpty) {
                          setState(() {
                            _dayPickerError = 'Select at least one day';
                          });
                          return;
                        }

                        setState(() => _saving = true);
                        final title = _titleCtrl.text.trim();

                        await context.read<HabitProvider>().addHabit(
                              uid: uid,
                              title: title,
                              category: _category,
                              frequency: _frequency,
                              selectedDays: _selectedDays.toList()..sort(),
                            );

                        if (_reminderTime != null) {
                          await NotificationService().scheduleDailyReminder(
                            id: title.hashCode,
                            title: 'DeenRoutine reminder',
                            body: 'Time for: $title',
                            hour: _reminderTime!.hour,
                            minute: _reminderTime!.minute,
                          );
                        }

                        if (mounted) Navigator.pop(context);
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}