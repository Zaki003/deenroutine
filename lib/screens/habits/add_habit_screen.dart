import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../models/habit_template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/habit_error_messages.dart';
import '../../widgets/tracking_type_section.dart';

class AddHabitScreen extends StatefulWidget {
  /// When set, the form opens pre-filled with this habit's values and saves
  /// via an update instead of creating a new habit.
  final Habit? editingHabit;

  /// When set (and [editingHabit] isn't), the form opens pre-filled from this
  /// template but still saves as a new habit — picking a template is just a
  /// head start, not a locked-in choice.
  final HabitTemplate? template;

  const AddHabitScreen({super.key, this.editingHabit, this.template});

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

  HabitTrackingType _trackingType = HabitTrackingType.yesNo;
  int _numericTarget = 1;
  String _numericUnit = '';
  final _numericUnitCtrl = TextEditingController();
  int _timerTargetMinutes = 10;
  final List<String> _checklistItems = [];
  final _checklistItemCtrl = TextEditingController();
  String? _checklistError;
  int _ratingScale = 5;

  bool get _isEditing => widget.editingHabit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.editingHabit;
    final template = widget.template;
    if (habit != null) {
      _titleCtrl.text = habit.title;
      _category = habit.category;
      _frequency = habit.frequency;
      _selectedDays.addAll(habit.selectedDays);
      if (habit.reminderHour != null && habit.reminderMinute != null) {
        _reminderTime =
            TimeOfDay(hour: habit.reminderHour!, minute: habit.reminderMinute!);
      }
      _trackingType = habit.trackingType;
      _numericTarget = habit.numericTarget;
      _numericUnit = habit.numericUnit;
      // Only show the custom field's text when the saved unit isn't one of
      // the preset chips — a preset match should just light up its chip,
      // not also echo into the "custom" field.
      if (!NumericConfigPanel.presetUnits.contains(habit.numericUnit)) {
        _numericUnitCtrl.text = habit.numericUnit;
      }
      _timerTargetMinutes = habit.timerTargetMinutes;
      _checklistItems.addAll(habit.checklistItems);
      _ratingScale = habit.ratingScale;
    } else if (template != null) {
      _titleCtrl.text = template.title;
      _category = template.category;
      _frequency = template.frequency;
      _trackingType = template.trackingType;
      _numericTarget = template.numericTarget;
      _numericUnit = template.numericUnit;
      if (!NumericConfigPanel.presetUnits.contains(template.numericUnit)) {
        _numericUnitCtrl.text = template.numericUnit;
      }
      _timerTargetMinutes = template.timerTargetMinutes;
      _checklistItems.addAll(template.checklistItems);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _numericUnitCtrl.dispose();
    _checklistItemCtrl.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final text = _checklistItemCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklistItems.add(text);
      _checklistItemCtrl.clear();
      _checklistError = null;
    });
  }

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
      appBar: AppBar(title: Text(_isEditing ? l10n.editHabitTitle : l10n.newHabitTitle)),
      body: SingleChildScrollView(
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
              TrackingTypePicker(
                selected: _trackingType,
                onChanged: (t) => setState(() {
                  _trackingType = t;
                  _checklistError = null;
                }),
              ),
              switch (_trackingType) {
                HabitTrackingType.numeric => NumericConfigPanel(
                    target: _numericTarget,
                    onTargetChanged: (v) => setState(() => _numericTarget = v),
                    unit: _numericUnit,
                    onUnitChanged: (v) => setState(() => _numericUnit = v),
                    unitController: _numericUnitCtrl,
                  ),
                HabitTrackingType.timer => TimerConfigPanel(
                    targetMinutes: _timerTargetMinutes,
                    onTargetMinutesChanged: (v) => setState(() => _timerTargetMinutes = v),
                  ),
                HabitTrackingType.checklist => ChecklistConfigPanel(
                    items: _checklistItems,
                    itemController: _checklistItemCtrl,
                    error: _checklistError,
                    onAdd: _addChecklistItem,
                    onRemoveAt: (i) => setState(() => _checklistItems.removeAt(i)),
                  ),
                HabitTrackingType.rating => RatingConfigPanel(
                    scale: _ratingScale,
                    onScaleChanged: (v) => setState(() => _ratingScale = v),
                  ),
                HabitTrackingType.yesNo =>
                  TrackingTypeInfoNote(text: l10n.yesNoInfoNote),
                HabitTrackingType.avoidance =>
                  TrackingTypeInfoNote(text: l10n.avoidanceInfoNote),
              },
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

                        if (_trackingType == HabitTrackingType.checklist &&
                            _checklistItems.isEmpty) {
                          setState(() {
                            _checklistError = l10n.checklistEmptyError;
                          });
                          return;
                        }

                        setState(() => _saving = true);
                        final title = _titleCtrl.text.trim();
                        final habitProvider = context.read<HabitProvider>();
                        final selectedDays = _selectedDays.toList()..sort();

                        final saved = _isEditing
                            ? await habitProvider.updateHabit(
                                original: widget.editingHabit!,
                                title: title,
                                category: _category,
                                frequency: _frequency,
                                selectedDays: selectedDays,
                                reminderHour: _reminderTime?.hour,
                                reminderMinute: _reminderTime?.minute,
                                trackingType: _trackingType,
                                numericTarget: _numericTarget,
                                numericUnit: _numericUnit.trim(),
                                timerTargetMinutes: _timerTargetMinutes,
                                checklistItems: List.of(_checklistItems),
                                ratingScale: _ratingScale,
                              )
                            : await habitProvider.addHabit(
                                uid: uid,
                                title: title,
                                category: _category,
                                frequency: _frequency,
                                selectedDays: selectedDays,
                                reminderHour: _reminderTime?.hour,
                                reminderMinute: _reminderTime?.minute,
                                trackingType: _trackingType,
                                numericTarget: _numericTarget,
                                numericUnit: _numericUnit.trim(),
                                timerTargetMinutes: _timerTargetMinutes,
                                checklistItems: List.of(_checklistItems),
                                ratingScale: _ratingScale,
                              );

                        if (!saved) {
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

                        // Notification scheduling is best-effort: the habit
                        // itself is already saved at this point, so a
                        // failure here (e.g. missing exact-alarm permission
                        // on Android 12+) must not trap the user on this
                        // screen with a spinner that never resolves.
                        try {
                          // The old title's notification id must be
                          // cancelled separately since a rename changes the
                          // id (it's derived from the title's hashCode).
                          if (_isEditing) {
                            await NotificationService().cancelReminder(
                                widget.editingHabit!.title.hashCode);
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
                        } catch (_) {
                          // Ignored: the habit saved successfully, which is
                          // what the user is waiting on. The reminder just
                          // won't fire until they reopen and re-save it.
                        }

                        if (mounted) Navigator.pop(context);
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? l10n.saveChangesButton : l10n.saveHabitButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
