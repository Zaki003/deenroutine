import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../theme/deen_colors.dart';

/// 2-column grid of every [HabitTrackingType], used by the add/edit habit
/// form. The active card fills with [DeenColors.heroGradient], matching the
/// Dashboard/Prayer hero cards.
class TrackingTypePicker extends StatelessWidget {
  final HabitTrackingType selected;
  final ValueChanged<HabitTrackingType> onChanged;

  const TrackingTypePicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.trackingTypeSectionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            for (final type in HabitTrackingType.values)
              _TrackingTypeCard(
                type: type,
                selected: type == selected,
                onTap: () => onChanged(type),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrackingTypeCard extends StatelessWidget {
  final HabitTrackingType type;
  final bool selected;
  final VoidCallback onTap;

  const _TrackingTypeCard({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected ? DeenColors.heroGradient : null,
          color: selected ? null : scheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, size: 20, color: selected ? Colors.white : scheme.primary),
            const SizedBox(height: 6),
            Text(
              type.label(l10n),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: selected ? Colors.white : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.blurb(l10n),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: selected ? Colors.white.withValues(alpha: 0.85) : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [HabitTrackingType.numeric] config: a target-amount stepper plus a unit
/// field (preset chips, or free text typed directly into the field).
///
/// [unit] is the authoritative selected value; [unitController] only drives
/// what the custom text field *displays*. They're kept separate so picking
/// a preset chip doesn't echo that word into the custom field — the field
/// stays on its placeholder unless the user is actually typing a custom
/// unit themselves.
class NumericConfigPanel extends StatelessWidget {
  final int target;
  final ValueChanged<int> onTargetChanged;
  final String unit;
  final ValueChanged<String> onUnitChanged;
  final TextEditingController unitController;

  const NumericConfigPanel({
    super.key,
    required this.target,
    required this.onTargetChanged,
    required this.unit,
    required this.onUnitChanged,
    required this.unitController,
  });

  static const presetUnits = ['pages', 'glasses', 'rakahs', 'km'];

  String _presetLabel(AppLocalizations l10n, String preset) {
    switch (preset) {
      case 'pages':
        return l10n.numericUnitPagesChip;
      case 'glasses':
        return l10n.numericUnitGlassesChip;
      case 'rakahs':
        return l10n.numericUnitRakahsChip;
      case 'km':
        return l10n.numericUnitKmChip;
      default:
        return preset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.numericTargetLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                onPressed: target > 1 ? () => onTargetChanged(target - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$target',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.outlined(
                onPressed: () => onTargetChanged(target + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.numericUnitLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final preset in presetUnits)
                ChoiceChip(
                  label: Text(_presetLabel(l10n, preset)),
                  selected: unit == preset,
                  onSelected: (_) {
                    unitController.clear();
                    onUnitChanged(preset);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: unitController,
            decoration: InputDecoration(labelText: l10n.numericUnitCustomHint),
            onChanged: onUnitChanged,
          ),
        ],
      ),
    );
  }
}

/// [HabitTrackingType.timer] config: target-duration chips plus a custom
/// minutes stepper (both edit the same underlying value).
class TimerConfigPanel extends StatelessWidget {
  final int targetMinutes;
  final ValueChanged<int> onTargetMinutesChanged;

  const TimerConfigPanel({
    super.key,
    required this.targetMinutes,
    required this.onTargetMinutesChanged,
  });

  static const _presets = [5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.timerTargetLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in _presets)
                ChoiceChip(
                  label: Text(l10n.timerMinutesChip(minutes)),
                  selected: targetMinutes == minutes,
                  onSelected: (_) => onTargetMinutesChanged(minutes),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(l10n.timerCustomMinutesLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              IconButton.outlined(
                onPressed: targetMinutes > 1 ? () => onTargetMinutesChanged(targetMinutes - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$targetMinutes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.outlined(
                onPressed: () => onTargetMinutesChanged(targetMinutes + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// [HabitTrackingType.checklist] config: a freeform list of items the user
/// builds by typing one and tapping add; each item is removable.
class ChecklistConfigPanel extends StatelessWidget {
  final List<String> items;
  final TextEditingController itemController;
  final String? error;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;

  const ChecklistConfigPanel({
    super.key,
    required this.items,
    required this.itemController,
    required this.error,
    required this.onAdd,
    required this.onRemoveAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.checklistItemsLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(items[i])),
                  IconButton(
                    onPressed: () => onRemoveAt(i),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: itemController,
                  decoration: InputDecoration(hintText: l10n.checklistItemInputHint),
                  onFieldSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// [HabitTrackingType.rating] config: the scale's upper bound.
class RatingConfigPanel extends StatelessWidget {
  final int scale;
  final ValueChanged<int> onScaleChanged;

  const RatingConfigPanel({super.key, required this.scale, required this.onScaleChanged});

  static const _presets = [3, 5, 10];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ratingScaleLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in _presets)
                ChoiceChip(
                  label: Text(l10n.ratingOutOfOption(n)),
                  selected: scale == n,
                  onSelected: (_) => onScaleChanged(n),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Plain explanatory note shown for tracking types with no config —
/// [HabitTrackingType.yesNo] and [HabitTrackingType.avoidance].
class TrackingTypeInfoNote extends StatelessWidget {
  final String text;

  const TrackingTypeInfoNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
      ),
    );
  }
}
