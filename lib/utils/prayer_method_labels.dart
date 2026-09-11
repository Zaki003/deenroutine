import '../l10n/app_localizations.dart';
import '../services/prayer_service.dart';

/// Localizes a [PrayerCalculationMethod] into its display name.
String prayerMethodLabel(AppLocalizations l10n, PrayerCalculationMethod method) {
  switch (method) {
    case PrayerCalculationMethod.karachi:
      return l10n.prayerMethodKarachi;
    case PrayerCalculationMethod.isna:
      return l10n.prayerMethodIsna;
    case PrayerCalculationMethod.mwl:
      return l10n.prayerMethodMwl;
    case PrayerCalculationMethod.ummAlQura:
      return l10n.prayerMethodUmmAlQura;
  }
}

/// Localizes an [AsrJuristicMethod] into its display name.
String asrMethodLabel(AppLocalizations l10n, AsrJuristicMethod school) {
  switch (school) {
    case AsrJuristicMethod.standard:
      return l10n.asrMethodStandard;
    case AsrJuristicMethod.hanafi:
      return l10n.asrMethodHanafi;
  }
}
