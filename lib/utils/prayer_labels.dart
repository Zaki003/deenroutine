import '../l10n/app_localizations.dart';
import '../models/prayer_log.dart';

/// Localizes an Aladhan API prayer key (e.g. `'Fajr'`) into its display
/// name. Falls back to the raw key for anything unrecognized.
String prayerNameLabel(AppLocalizations l10n, String prayerKey) {
  switch (prayerKey) {
    case 'Fajr':
      return l10n.prayerFajr;
    case 'Dhuhr':
      return l10n.prayerDhuhr;
    case 'Asr':
      return l10n.prayerAsr;
    case 'Maghrib':
      return l10n.prayerMaghrib;
    case 'Isha':
      return l10n.prayerIsha;
    default:
      return prayerKey;
  }
}

/// How a logged prayer reads under its name on the Prayer screen.
String prayerStatusLabel(AppLocalizations l10n, PrayerStatus status) {
  switch (status) {
    case PrayerStatus.onTime:
      return l10n.prayerStatusOnTime;
    case PrayerStatus.late:
      return l10n.prayerStatusLate;
    case PrayerStatus.qada:
      return l10n.prayerStatusQada;
    case PrayerStatus.missed:
      return l10n.prayerStatusMissed;
  }
}

/// The same states as choices in the Prayer screen's hold-to-edit sheet.
String prayerOptionLabel(AppLocalizations l10n, PrayerStatus status) {
  switch (status) {
    case PrayerStatus.onTime:
      return l10n.prayerOptionOnTime;
    case PrayerStatus.late:
      return l10n.prayerOptionLate;
    case PrayerStatus.qada:
      return l10n.prayerOptionQada;
    case PrayerStatus.missed:
      return l10n.prayerOptionMissed;
  }
}
