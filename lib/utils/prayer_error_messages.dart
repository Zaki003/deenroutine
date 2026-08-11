import '../l10n/app_localizations.dart';
import '../services/prayer_service.dart';

String prayerErrorMessage(AppLocalizations l10n, PrayerErrorType type, String? detail) {
  switch (type) {
    case PrayerErrorType.locationServicesDisabled:
      return l10n.prayerErrorLocationDisabled;
    case PrayerErrorType.permissionDenied:
      return l10n.prayerErrorPermissionDenied;
    case PrayerErrorType.permissionDeniedForever:
      return l10n.prayerErrorPermissionDeniedForever;
    case PrayerErrorType.fetchFailed:
      return l10n.prayerErrorFetchFailed(detail ?? '');
    case PrayerErrorType.unknown:
      return l10n.prayerErrorUnknown;
  }
}
