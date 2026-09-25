import '../l10n/app_localizations.dart';
import '../providers/prayer_log_provider.dart';

/// Maps a [PrayerLogErrorType] to a localized message.
String prayerLogErrorMessage(AppLocalizations l10n, PrayerLogErrorType type) {
  switch (type) {
    case PrayerLogErrorType.syncFailed:
      return l10n.prayerLogSyncFailed;
    case PrayerLogErrorType.saveFailed:
      return l10n.prayerLogSaveFailed;
    case PrayerLogErrorType.historyFailed:
      return l10n.prayerLogHistoryFailed;
  }
}
