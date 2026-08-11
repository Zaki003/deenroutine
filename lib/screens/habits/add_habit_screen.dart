import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/habit_error_messages.dart';

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
  /// S M T W T F S order (0=Sun ... 6=Sat) from [weekdayShortNames].
  final Set<int> _selectedDays = {};
  String? _dayPickerError;

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Widget _buildDayPicker(AppLocalizations l10n) {
    final names = weekdayShortNames(l10n);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.repeatOnLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    names[index].substring(0, 1),
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newHabitTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(labelText: l10n.habitTitleLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.habitTitleValidatorError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitCategory>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l10n.categoryLabel),
                items: HabitCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.label(l10n))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitFrequency>(
                initialValue: _frequency,
                decoration: InputDecoration(labelText: l10n.frequencyLabel),
                items: HabitFrequency.values
                    .map((f) => DropdownMenuItem(value: f, child: Text(f.label(l10n))))
                    .toList(),
                onChanged: (v) => setState(() {
                  _frequency = v!;
                  if (_frequency != HabitFrequency.specificDays) {
                    _selectedDays.clear();
                    _dayPickerError = null;
                  }
                }),
              ),
              if (_frequency == HabitFrequency.specificDays) _buildDayPicker(l10n),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_outlined),
                title: Text(l10n.dailyReminderTitle),
                subtitle: Text(
                  _reminderTime == null
                      ? l10n.reminderOffSubtitle
                      : l10n.reminderAtTime(_reminderTime!.format(context)),
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
                            _dayPickerError = l10n.selectAtLeastOneDay;
                          });
                          return;
                        }

                        setState(() => _saving = true);
                        final title = _titleCtrl.text.trim();
                        final habitProvider = context.read<HabitProvider>();

                        final added = await habitProvider.addHabit(
                          uid: uid,
                          title: title,
                          category: _category,
                          frequency: _frequency,
                          selectedDays: _selectedDays.toList()..sort(),
                        );

                        if (!added) {
                          if (!mounted) return;
                          setState(() => _saving = false);
                          final errorType = habitProvider.errorType;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                errorType != null
                                    ? habitErrorMessage(
                                        l10n, errorType, habitProvider.errorDetail)
                                    : l10n.habitSaveFailedGeneric,
                              ),
                            ),
                          );
                          habitProvider.clearError();
                          return;
                        }

                        if (_reminderTime != null) {
                          await NotificationService().scheduleDailyReminder(
                            id: title.hashCode,
                            title: l10n.reminderNotificationTitle,
                            body: l10n.reminderNotificationBody(title),
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
                    : Text(l10n.saveHabitButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
