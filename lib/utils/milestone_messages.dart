import '../l10n/app_localizations.dart';

/// Localized title/subtitle for a [days]-day streak milestone banner. Only
/// called for a day count in [milestoneDays] — everything else maps to
/// English/Bangla text here so [HabitProvider] can stay
/// `AppLocalizations`/`BuildContext`-free.
({String title, String subtitle}) milestoneMessage(
  AppLocalizations l10n,
  int days,
  String habitTitle,
) {
  switch (days) {
    case 3:
      return (title: l10n.milestoneTitle3, subtitle: l10n.milestoneSubtitle3(days, habitTitle));
    case 7:
      return (title: l10n.milestoneTitle7, subtitle: l10n.milestoneSubtitle7(days, habitTitle));
    case 30:
      return (title: l10n.milestoneTitle30, subtitle: l10n.milestoneSubtitle30(days, habitTitle));
    case 100:
      return (title: l10n.milestoneTitle100, subtitle: l10n.milestoneSubtitle100(days, habitTitle));
    case 365:
      return (title: l10n.milestoneTitle365, subtitle: l10n.milestoneSubtitle365(days, habitTitle));
    default:
      return (title: l10n.milestoneTitle3, subtitle: l10n.milestoneSubtitle3(days, habitTitle));
  }
}
