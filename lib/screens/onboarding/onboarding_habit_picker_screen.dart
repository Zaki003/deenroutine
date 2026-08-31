import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../models/habit_template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/onboarding_scaffold.dart';

class OnboardingHabitPickerScreen extends StatefulWidget {
  const OnboardingHabitPickerScreen({super.key});

  @override
  State<OnboardingHabitPickerScreen> createState() => _OnboardingHabitPickerScreenState();
}

class _OnboardingHabitPickerScreenState extends State<OnboardingHabitPickerScreen> {
  final Set<HabitTemplate> _selected = {};
  bool _saving = false;

  Future<void> _addAndFinish() async {
    setState(() => _saving = true);
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final habitProvider = context.read<HabitProvider>();
    for (final template in _selected) {
      await habitProvider.addHabit(
        uid: uid,
        title: template.title,
        category: template.category,
        frequency: template.frequency,
        trackingType: template.trackingType,
        checklistItems: template.checklistItems,
        numericTarget: template.numericTarget,
        numericUnit: template.numericUnit,
        timerTargetMinutes: template.timerTargetMinutes,
      );
    }
    if (!mounted) return;
    _finishOnboarding();
  }

  void _skip() => _finishOnboarding();

  void _finishOnboarding() {
    context.read<AuthProvider>().finishOnboarding();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final templates = habitTemplates(l10n);

    return OnboardingScaffold(
      activeDotIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStaggerIn(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboardingHabitPickerHeadline,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DeenColors.primaryText(dark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.onboardingHabitPickerSubtitle,
                  style: TextStyle(fontSize: 13, color: DeenColors.textMuted(dark)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: OnboardingStaggerIn(
              index: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final category in HabitCategory.values)
                      if (templates.any((t) => t.category == category))
                        _PickerCategorySection(
                          category: category,
                          templates: templates.where((t) => t.category == category).toList(),
                          selected: _selected,
                          dark: dark,
                          onToggle: (t) => setState(() {
                            if (!_selected.remove(t)) _selected.add(t);
                          }),
                        ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _addAndFinish,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.onboardingAddHabitsButton(_selected.length)),
            ),
          ),
          TextButton(onPressed: _saving ? null : _skip, child: Text(l10n.onboardingSkipHabitsButton)),
        ],
      ),
    );
  }
}

class _PickerCategorySection extends StatelessWidget {
  final HabitCategory category;
  final List<HabitTemplate> templates;
  final Set<HabitTemplate> selected;
  final bool dark;
  final ValueChanged<HabitTemplate> onToggle;

  const _PickerCategorySection({
    required this.category,
    required this.templates,
    required this.selected,
    required this.dark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.label(l10n), style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in templates)
                _OnboardingTemplateChip(
                  template: t,
                  selected: selected.contains(t),
                  dark: dark,
                  onTap: () => onToggle(t),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Same 96px/icon-above-title footprint as habit_template_sheet.dart's
/// private _TemplateChip, layered with quiz_home_screen.dart's _LengthChip
/// selected/unselected fill treatment — this needs both: a card sized for a
/// template, but a toggle state that sheet's chip never had.
class _OnboardingTemplateChip extends StatelessWidget {
  final HabitTemplate template;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _OnboardingTemplateChip({
    required this.template,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? DeenColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? DeenColors.primary : DeenColors.outlineFaint(dark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(template.icon, size: 18, color: selected ? Colors.white : DeenColors.textMuted(dark)),
              const SizedBox(height: 8),
              Text(
                template.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : DeenColors.primaryText(dark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
