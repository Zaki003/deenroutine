import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../models/habit_template.dart';
import '../screens/habits/add_habit_screen.dart';
import '../theme/deen_colors.dart';
import 'deen_card.dart';

/// Opens the "add a habit" entry point: a sheet offering a blank form or a
/// starter template, grouped by category. Tapping either dismisses the sheet
/// and pushes [AddHabitScreen], pre-filled in the template case — shared by
/// every add-habit button in the app so they behave identically.
Future<void> showHabitTemplateSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _HabitTemplateSheet(),
  );
}

class _HabitTemplateSheet extends StatelessWidget {
  const _HabitTemplateSheet();

  void _openAddHabit(BuildContext context, {HabitTemplate? template}) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddHabitScreen(template: template)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final templates = habitTemplates(l10n);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openAddHabit(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DeenColors.gold,
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 15, color: DeenColors.ink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.createYourOwnHabit,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: DeenColors.primaryText(dark),
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: DeenColors.textMuted(dark)),
                    ],
                  ),
                ),
              ),
              Divider(height: 24, color: DeenColors.dividerLine(dark)),
              for (final category in HabitCategory.values)
                if (templates.any((t) => t.category == category))
                  _CategorySection(
                    category: category,
                    templates:
                        templates.where((t) => t.category == category).toList(),
                    dark: dark,
                    onSelect: (template) =>
                        _openAddHabit(context, template: template),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final HabitCategory category;
  final List<HabitTemplate> templates;
  final bool dark;
  final ValueChanged<HabitTemplate> onSelect;

  const _CategorySection({
    required this.category,
    required this.templates,
    required this.dark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label(l10n),
            style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark)),
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < templates.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _TemplateChip(
                      template: templates[i],
                      dark: dark,
                      onTap: () => onSelect(templates[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final HabitTemplate template;
  final bool dark;
  final VoidCallback onTap;

  const _TemplateChip(
      {required this.template, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: DeenCard(
          dark: dark,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(template.icon, size: 18, color: DeenColors.textMuted(dark)),
              const SizedBox(height: 8),
              Text(
                template.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: DeenColors.primaryText(dark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
