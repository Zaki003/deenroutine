import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/prayer_provider.dart';
import '../services/prayer_service.dart';
import '../theme/deen_colors.dart';
import '../utils/prayer_method_labels.dart';

/// Opens the calculation-method/Asr-school picker, triggered from the
/// "Prayer calculation method" row on Profile. Stays open across taps
/// (unlike [confirmUpdateLocation]'s pick-one-and-close sheet) since there
/// are two independent choices to make here.
Future<void> confirmPrayerMethod(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _PrayerMethodSheet(),
  );
}

class _PrayerMethodSheet extends StatelessWidget {
  const _PrayerMethodSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PrayerProvider>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.prayerMethodTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            for (final method in PrayerCalculationMethod.values)
              _OptionRow(
                label: prayerMethodLabel(l10n, method),
                selected: provider.calculationMethod == method,
                dark: dark,
                onTap: () => provider.setCalculationMethod(method),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.asrMethodTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: DeenColors.textMuted(dark),
              ),
            ),
            for (final school in AsrJuristicMethod.values)
              _OptionRow(
                label: asrMethodLabel(l10n, school),
                selected: provider.asrMethod == school,
                dark: dark,
                onTap: () => provider.setAsrMethod(school),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: DeenColors.primaryText(dark))),
            if (selected) const Icon(Icons.check_rounded, size: 18, color: DeenColors.primary),
          ],
        ),
      ),
    );
  }
}
