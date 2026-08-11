import '../l10n/app_localizations.dart';

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
